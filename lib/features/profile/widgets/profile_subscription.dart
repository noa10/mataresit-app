import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';

class ProfileSubscription extends ConsumerWidget {
  final UserModel profile;

  const ProfileSubscription({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Plan Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                      decoration: BoxDecoration(
                        color: _getSubscriptionColor(profile.subscriptionTier ?? 'free'),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getSubscriptionDisplayName(profile.subscriptionTier ?? 'free'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(profile.subscriptionStatus ?? 'active'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (profile.subscriptionStatus ?? 'active').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Usage Information
                if (profile.receiptsUsedThisMonth != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage This Month',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.smallPadding),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Text(
                            '${profile.receiptsUsedThisMonth} receipts processed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Subscription Dates
        if (profile.subscriptionStartDate != null || profile.subscriptionEndDate != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  if (profile.subscriptionStartDate != null)
                    _buildDetailRow(
                      context,
                      'Started',
                      _formatDate(profile.subscriptionStartDate!),
                      Icons.play_arrow,
                    ),
                  
                  if (profile.subscriptionEndDate != null)
                    _buildDetailRow(
                      context,
                      'Expires',
                      _formatDate(profile.subscriptionEndDate!),
                      Icons.event,
                    ),
                  
                  if (profile.nextBillingDate != null)
                    _buildDetailRow(
                      context,
                      'Next Billing',
                      _formatDate(profile.nextBillingDate!),
                      Icons.payment,
                    ),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        // Action Buttons
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Subscription',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/pricing'),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Upgrade Plan'),
                  ),
                ),
                
                const SizedBox(height: AppConstants.smallPadding),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/billing'),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Billing & Payments'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return Colors.amber;
      case 'pro':
        return Colors.purple;
      case 'enterprise':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'past_due':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSubscriptionDisplayName(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return 'Free Plan';
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tier.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
