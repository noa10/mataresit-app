import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/profile_service.dart';
import '../widgets/avatar_upload_widget.dart';

class ProfileHeader extends ConsumerWidget {
  final UserModel profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fullName = ProfileService.getFullName(profile);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          AvatarUploadWidget(
            profile: profile,
            size: 120,
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Name
          Text(
            fullName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.smallPadding),
          
          // Email
          if (profile.email != null)
            Text(
              profile.email!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Subscription Badge
          if (profile.subscriptionTier != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              decoration: BoxDecoration(
                color: _getSubscriptionColor(profile.subscriptionTier!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getSubscriptionDisplayName(profile.subscriptionTier!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
}
