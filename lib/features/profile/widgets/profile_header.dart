import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/profile_service.dart';
import '../widgets/avatar_upload_widget.dart';

/// Ledger-style identity block at the top of the profile screen.
class ProfileHeader extends ConsumerWidget {
  final UserModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fullName = ProfileService.getFullName(profile);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          AvatarUploadWidget(profile: profile, size: 96),

          const SizedBox(height: 16),

          Text(
            fullName,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: 'InstrumentSerif',
              fontSize: 30,
              height: 1.05,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          if (profile.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile.email!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (profile.subscriptionTier != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getSubscriptionDisplayName(
                  profile.subscriptionTier!,
                ).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
        return tier;
    }
  }
}
