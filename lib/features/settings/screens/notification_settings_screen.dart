import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/notification_preferences_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/notification_preferences_provider.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
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
        title: const Text('Notification Settings'),
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
    if (state.isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (state.error != null) {
      return Center(
        child: AppErrorWidget(
          error: state.error!,
          onRetry: () => notifier.loadPreferences(),
        ),
      );
    }

    if (state.preferences == null) {
      return const Center(
        child: Text('No notification preferences found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Push Notifications Section
          _buildPushNotificationsSection(context, state.preferences!, notifier),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Email Notifications Section
          _buildEmailNotificationsSection(context, state.preferences!, notifier),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Notification Categories
          ...notificationCategories.entries.map((entry) =>
            _buildCategorySection(context, entry.key, entry.value, state.preferences!, notifier),
          ),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Quiet Hours Section
          _buildQuietHoursSection(context, state.preferences!, notifier),
          
          const SizedBox(height: AppConstants.largePadding),
          
          // Digest Settings Section
          _buildDigestSection(context, state.preferences!, notifier),
          
          const SizedBox(height: AppConstants.largePadding * 2),
        ],
      ),
    );
  }

  Widget _buildPushNotificationsSection(
    BuildContext context,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Push Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Get instant notifications on your device',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SwitchListTile(
              title: const Text('Enable push notifications'),
              subtitle: const Text('Master switch for all push notifications'),
              value: preferences.pushEnabled,
              onChanged: (value) => notifier.togglePushNotifications(value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailNotificationsSection(
    BuildContext context,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.email,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Email Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Receive notifications via email',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SwitchListTile(
              title: const Text('Enable email notifications'),
              subtitle: const Text('Master switch for all email notifications'),
              value: preferences.emailEnabled,
              onChanged: (value) => notifier.toggleEmailNotifications(value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    NotificationCategory category,
    NotificationCategoryConfig config,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        config.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...config.types.map((type) => _buildNotificationTypeRow(
              context,
              type,
              preferences,
              notifier,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeRow(
    BuildContext context,
    NotificationType type,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    final emailEnabled = preferences.getEmailPreference(type);
    final pushEnabled = preferences.getPushPreference(type);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getNotificationTypeLabel(type),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // Email toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.email,
                size: 16,
                color: preferences.emailEnabled ? Colors.grey[600] : Colors.grey[400],
              ),
              Switch(
                value: emailEnabled,
                onChanged: preferences.emailEnabled 
                  ? (value) => notifier.updateEmailPreference(type, value)
                  : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(width: AppConstants.smallPadding),
          // Push toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications,
                size: 16,
                color: preferences.pushEnabled ? Colors.grey[600] : Colors.grey[400],
              ),
              Switch(
                value: pushEnabled,
                onChanged: preferences.pushEnabled 
                  ? (value) => notifier.updatePushPreference(type, value)
                  : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursSection(
    BuildContext context,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bedtime,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Quiet Hours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Disable notifications during specific hours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SwitchListTile(
              title: const Text('Enable quiet hours'),
              subtitle: const Text('Notifications will be silenced during these hours'),
              value: preferences.quietHoursEnabled,
              onChanged: (value) => notifier.updateQuietHours(enabled: value),
              contentPadding: EdgeInsets.zero,
            ),
            if (preferences.quietHoursEnabled) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      context,
                      'Start Time',
                      preferences.quietHoursStart ?? '22:00',
                      (time) => notifier.updateQuietHours(
                        enabled: preferences.quietHoursEnabled,
                        startTime: time,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildTimeSelector(
                      context,
                      'End Time',
                      preferences.quietHoursEnd ?? '06:00',
                      (time) => notifier.updateQuietHours(
                        enabled: preferences.quietHoursEnabled,
                        endTime: time,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigestSection(
    BuildContext context,
    NotificationPreferences preferences,
    NotificationPreferencesNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Digest Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Receive periodic summaries of your notifications',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            SwitchListTile(
              title: const Text('Daily digest'),
              subtitle: const Text('Receive a daily summary of notifications'),
              value: preferences.dailyDigestEnabled,
              onChanged: (value) => notifier.updateDigestPreferences(dailyEnabled: value),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Weekly digest'),
              subtitle: const Text('Receive a weekly summary of notifications'),
              value: preferences.weeklyDigestEnabled,
              onChanged: (value) => notifier.updateDigestPreferences(weeklyEnabled: value),
              contentPadding: EdgeInsets.zero,
            ),
            if (preferences.dailyDigestEnabled || preferences.weeklyDigestEnabled) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildTimeSelector(
                context,
                'Digest Time',
                preferences.digestTime ?? '09:00',
                (time) => notifier.updateDigestPreferences(digestTime: time),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    String currentTime,
    Function(String) onTimeChanged,
  ) {
    return InkWell(
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
          final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              currentTime,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.receiptProcessing:
        return Icons.receipt_long;
      case NotificationCategory.teamCollaboration:
        return Icons.group;
      case NotificationCategory.claimsAndBilling:
        return Icons.account_balance_wallet;
    }
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
