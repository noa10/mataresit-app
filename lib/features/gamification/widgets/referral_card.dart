import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../models/gamification_profile.dart';
import '../providers/gamification_provider.dart';

/// The user's referral code plus a form to redeem someone else's.
class ReferralCard extends ConsumerStatefulWidget {
  const ReferralCard({super.key, required this.profile});

  final GamificationProfile profile;

  @override
  ConsumerState<ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends ConsumerState<ReferralCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    _showMessage('gamification.referral.copied'.tr());
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _isRedeeming) return;

    setState(() => _isRedeeming = true);
    try {
      // The RPC answers with a boolean: `false` is a rejected code, not an error.
      final redeemed = await ref
          .read(gamificationProfileProvider.notifier)
          .redeemReferralCode(code);
      if (!context.mounted) return;
      if (redeemed) _controller.clear();
      _showMessage(
        redeemed
            ? 'gamification.referral.redeem_success'.tr()
            : 'gamification.referral.redeem_failed'.tr(),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showMessage('gamification.referral.redeem_failed'.tr());
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = widget.profile.referralCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'gamification.referral.title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'gamification.referral.successful'.tr(
                namedArgs: {'count': '${widget.profile.successfulReferrals}'},
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'gamification.referral.your_code'.tr(),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            if (code == null || code.isEmpty)
              Text(
                'gamification.referral.no_code'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                      child: Text(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  IconButton(
                    onPressed: () => _copyCode(code),
                    icon: const Icon(Icons.copy),
                    tooltip: 'gamification.referral.copy'.tr(),
                  ),
                ],
              ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'gamification.referral.redeem_label'.tr(),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: 'gamification.referral.redeem_hint'.tr(),
                    ),
                    onSubmitted: (_) => _redeem(),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                FilledButton(
                  onPressed: _isRedeeming ? null : _redeem,
                  child: _isRedeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('gamification.referral.redeem_action'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
