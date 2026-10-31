import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/notification_preferences_model.dart';
import '../providers/notification_preferences_provider.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load preferences when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationPreferencesProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationPreferencesState state,
    NotificationPreferencesNotifier notifier,
  ) {
    final preferences = state.preferences;

    return RefreshIndicator(
      onRefresh: () => notifier.loadPreferences(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _buildPageHeader(context, state),
          const SizedBox(height: 20),
          if (state.isLoading && preferences == null)
            _buildLoadingPanel(context)
          else if (state.error != null && preferences == null)
            _buildErrorPanel(context, state.error!, notifier)
          else if (preferences == null)
            _buildEmptyPanel(context)
          else ...[
            if (state.updateError != null) ...[
              _buildUpdateError(context, state.updateError!),
              const SizedBox(height: 16),
            ],
            ..._buildPreferenceSections(context, preferences, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildPageHeader(
    BuildContext context,
    NotificationPreferencesState state,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOTIFICATION PREFERENCES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Notifications',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'InstrumentSerif',
                  fontSize: 32,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Control what reaches you, and when.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (state.isUpdating)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: Text(
              'SAVING',
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'IBMPlexMono',
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPreferenceSections(
    BuildContext context,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    final categories = notificationCategories.entries.toList();

    return [
      _buildSection(
        context,
        'Delivery',
        _buildPanel(
          context,
          rows: [
            _buildSwitchRow(
              context,
              title: 'Push notifications',
              description: 'Get instant notifications on your device',
              value: preferences.pushEnabled,
              onChanged: notifier.togglePushNotifications,
            ),
            _buildSwitchRow(
              context,
              title: 'Email notifications',
              description: 'Receive notifications via email',
              value: preferences.emailEnabled,
              onChanged: notifier.toggleEmailNotifications,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _buildSection(
        context,
        'Categories',
        Column(
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildCategoryPanel(
                context,
                categories[i].value,
                preferences,
                notifier,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      _buildSection(
        context,
        'Quiet hours',
        _buildPanel(
          context,
          rows: [
            _buildSwitchRow(
              context,
              title: 'Enable quiet hours',
              description: 'Notifications will be silenced during these hours',
              value: preferences.quietHoursEnabled,
              onChanged: (value) => notifier.updateQuietHours(enabled: value),
            ),
            if (preferences.quietHoursEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        context,
                        'Start time',
                        preferences.quietHoursStart ?? '22:00',
                        (time) => notifier.updateQuietHours(
                          enabled: preferences.quietHoursEnabled,
                          startTime: time,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeSelector(
                        context,
                        'End time',
                        preferences.quietHoursEnd ?? '06:00',
                        (time) => notifier.updateQuietHours(
                          enabled: preferences.quietHoursEnabled,
                          endTime: time,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _buildSection(
        context,
        'Digests',
        _buildPanel(
          context,
          rows: [
            _buildSwitchRow(
              context,
              title: 'Daily digest',
              description: 'Receive a daily summary of notifications',
              value: preferences.dailyDigestEnabled,
              onChanged: (value) =>
                  notifier.updateDigestPreferences(dailyEnabled: value),
            ),
            _buildSwitchRow(
              context,
              title: 'Weekly digest',
              description: 'Receive a weekly summary of notifications',
              value: preferences.weeklyDigestEnabled,
              onChanged: (value) =>
                  notifier.updateDigestPreferences(weeklyEnabled: value),
            ),
            if (preferences.dailyDigestEnabled ||
                preferences.weeklyDigestEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: _buildTimeSelector(
                  context,
                  'Digest time',
                  preferences.digestTime ?? '09:00',
                  (time) => notifier.updateDigestPreferences(digestTime: time),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSection(BuildContext context, String label, Widget child) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    Widget? header,
    required List<Widget> rows,
  }) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (header != null) {
      children.add(header);
      children.add(
        Divider(height: 1, thickness: 1, color: colors.outlineVariant),
      );
    }

    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
        );
      }
      children.add(rows[i]);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildPanelHeader(
    BuildContext context,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPanel(
    BuildContext context,
    NotificationCategoryConfig config,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    final rows = <Widget>[
      for (final type in config.types)
        _buildNotificationTypeRow(context, type, preferences, notifier),
    ];

    return _buildPanel(
      context,
      header: _buildPanelHeader(context, config.label, config.description),
      rows: rows,
    );
  }

  Widget _buildNotificationTypeRow(
    BuildContext context,
    NotificationType type,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final emailEnabled = preferences.getEmailPreference(type);
    final pushEnabled = preferences.getPushPreference(type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getNotificationTypeLabel(type),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.3,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildChannelSwitch(
            context,
            label: 'EMAIL',
            value: emailEnabled,
            onChanged: preferences.emailEnabled
                ? (value) => notifier.updateEmailPreference(type, value)
                : null,
          ),
          const SizedBox(width: 6),
          _buildChannelSwitch(
            context,
            label: 'PUSH',
            value: pushEnabled,
            onChanged: preferences.pushEnabled
                ? (value) => notifier.updatePushPreference(type, value)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSwitch(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onChanged != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
            color: enabled
                ? colors.onSurfaceVariant
                : colors.onSurfaceVariant.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 2),
        _buildSwitch(context, value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String title,
    String? description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSwitch(context, value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: colors.onPrimary,
      activeTrackColor: colors.primary,
      inactiveThumbColor: colors.onSurfaceVariant,
      inactiveTrackColor: colors.surfaceContainerHighest,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.outlineVariant,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    String currentTime,
    Function(String) onTimeChanged,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final timeParts = currentTime.split(':');
          final initialTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );

          final selectedTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );

          if (selectedTime != null) {
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
            onTimeChanged(formattedTime);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    currentTime,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _buildPanel(
      context,
      rows: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Loading notification preferences…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel(
    BuildContext context,
    String error,
    NotificationPreferencesNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _buildPanel(
      context,
      rows: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 30, color: colors.error),
              const SizedBox(height: 10),
              Text(
                'Couldn\'t load notification preferences',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => notifier.loadPreferences(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _buildPanel(
      context,
      rows: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: [
              Icon(
                Icons.notifications_none,
                size: 32,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No notification preferences found',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateError(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Couldn\'t save your changes. $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.receiptProcessingStarted:
        return 'Receipt processing started';
      case NotificationType.receiptProcessingCompleted:
        return 'Receipt processing completed';
      case NotificationType.receiptProcessingFailed:
        return 'Receipt processing failed';
      case NotificationType.receiptReadyForReview:
        return 'Receipt ready for review';
      case NotificationType.receiptBatchCompleted:
        return 'Receipt batch completed';
      case NotificationType.receiptBatchFailed:
        return 'Receipt batch failed';
      case NotificationType.receiptShared:
        return 'Receipt shared';
      case NotificationType.receiptCommentAdded:
        return 'Receipt comment added';
      case NotificationType.receiptEditedByTeamMember:
        return 'Receipt edited by team member';
      case NotificationType.receiptApprovedByTeam:
        return 'Receipt approved by team';
      case NotificationType.receiptFlaggedForReview:
        return 'Receipt flagged for review';
      case NotificationType.teamInvitationSent:
        return 'Team invitation sent';
      case NotificationType.teamInvitationAccepted:
        return 'Team invitation accepted';
      case NotificationType.teamMemberJoined:
        return 'Team member joined';
      case NotificationType.teamMemberLeft:
        return 'Team member left';
      case NotificationType.teamMemberRemoved:
        return 'Team member removed';
      case NotificationType.teamMemberRoleChanged:
        return 'Team member role changed';
      case NotificationType.teamSettingsUpdated:
        return 'Team settings updated';
      case NotificationType.claimSubmitted:
        return 'Claim submitted';
      case NotificationType.claimApproved:
        return 'Claim approved';
      case NotificationType.claimRejected:
        return 'Claim rejected';
      case NotificationType.claimReviewRequested:
        return 'Claim review requested';
    }
  }
}
