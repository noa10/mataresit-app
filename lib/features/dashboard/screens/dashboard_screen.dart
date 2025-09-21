import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../app/router/app_router.dart';
import '../../subscription/widgets/subscription_status_card.dart';
import '../../subscription/widgets/subscription_limits_widget.dart';
import '../../../shared/providers/currency_provider.dart';
import '../../../shared/utils/currency_utils.dart';
import '../../../shared/widgets/mataresit_logo.dart';
import '../../../shared/widgets/enhanced_user_avatar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final userPreferredCurrency = ref.watch(userPreferredCurrencyProvider);

    debugPrint('🔍 DASHBOARD SCREEN DEBUG: build() called, user=${user?.id}');
    debugPrint(
      '🔍 DASHBOARD SCREEN DEBUG: stats totalReceipts=${stats.totalReceipts}, totalAmount=${stats.totalAmount}',
    );
    debugPrint('🔍 DASHBOARD SCREEN DEBUG: Platform.isIOS = ${Platform.isIOS}');

    return Scaffold(
      appBar: AppBar(
        title: const MataresitLogoHorizontal(
          size: 28.0,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh receipts data which will update dashboard stats
          ref.invalidate(dashboardStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      WelcomeAvatar(
                        user: user,
                        onTap: () {
                          // Navigate to profile screen
                          context.push(AppRoutes.profile);
                        },
                      ),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.fullName ?? 'User',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (user?.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                user!.email!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Profile action button
                      IconButton(
                        onPressed: () => context.push(AppRoutes.profile),
                        icon: const Icon(Icons.arrow_forward_ios),
                        iconSize: 16,
                        tooltip: 'View Profile',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Subscription Status
              const SubscriptionStatusCard(),

              const SizedBox(height: AppConstants.defaultPadding),

              // Subscription Limits
              const SubscriptionLimitsWidget(
                showUpgradePrompt: true,
                compact: true,
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Quick Stats
              Text(
                'Quick Stats',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Receipts',
                      stats.totalReceipts.toString(),
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'This Month',
                      stats.thisMonthReceipts.toString(),
                      Icons.calendar_month,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Amount',
                      CurrencyUtils.formatCurrencySafe(
                        stats.totalAmount,
                        userPreferredCurrency,
                      ),
                      Icons.attach_money,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Teams',
                      stats.totalTeams.toString(),
                      Icons.groups,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Capture Receipt',
                      Icons.camera_alt,
                      Colors.blue,
                      () => context.push(AppRoutes.receiptCapture),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      'Analytics',
                      Icons.analytics,
                      Colors.green,
                      () => context.push(AppRoutes.analytics),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              if (stats.recentReceipts.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'No recent activity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Start by capturing your first receipt!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...stats.recentReceipts.map(
                  (receipt) => Card(
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.smallPadding,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.receipt,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(receipt.merchantName ?? 'Unknown Merchant'),
                      subtitle: Text(timeago.format(receipt.createdAt)),
                      trailing: receipt.totalAmount != null
                          ? Text(
                              CurrencyUtils.formatCurrencySafe(
                                receipt.totalAmount,
                                receipt.currency ?? userPreferredCurrency,
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            )
                          : null,
                      onTap: () => context.push('/receipts/${receipt.id}'),
                    ),
                  ),
                ),

              // Category Breakdown
              if (stats.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: AppConstants.largePadding),
                Text(
                  'Category Breakdown',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: stats.categoryBreakdown.entries.map((entry) {
                        final percentage =
                            (entry.value / stats.totalReceipts * 100).round();
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.smallPadding,
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value} ($percentage%)'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
