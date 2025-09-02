import 'package:flutter/material.dart';
import '../../../shared/models/claim_requests.dart';
import '../../../shared/utils/currency_utils.dart';

class ClaimStatsCard extends StatelessWidget {
  final ClaimStats stats;

  const ClaimStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claims Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Top row - Total claims and amounts
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.receipt_long,
                    label: 'Total Claims',
                    value: stats.totalClaims.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.attach_money,
                    label: 'Total Amount',
                    value: CurrencyUtils.formatCurrency(stats.totalAmount, 'USD'),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Second row - Status breakdown
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.hourglass_empty,
                    label: 'Pending',
                    value: stats.pendingClaims.toString(),
                    color: Colors.orange,
                    subtitle: '${stats.pendingRate.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.check_circle,
                    label: 'Approved',
                    value: stats.approvedClaims.toString(),
                    color: Colors.green,
                    subtitle: '${stats.approvalRate.toStringAsFixed(1)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.cancel,
                    label: 'Rejected',
                    value: stats.rejectedClaims.toString(),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Third row - Approved amount and processing time
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.payment,
                    label: 'Approved Amount',
                    value: CurrencyUtils.formatCurrency(stats.approvedAmount, 'USD'),
                    color: Colors.green,
                  ),
                ),
                if (stats.averageProcessingTime != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.schedule,
                      label: 'Avg. Processing',
                      value: _formatProcessingTime(stats.averageProcessingTime!),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatProcessingTime(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '${minutes}m';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      final days = (hours / 24).round();
      return '${days}d';
    }
  }
}
