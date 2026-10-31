import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

const _loginRoute = '/login';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: TextStyle(color: colors.onError)),
            backgroundColor: colors.error,
          ),
        );
      }

      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authCopy(
                context,
                'Password reset email sent! Check your inbox.',
                'E-mel set semula kata laluan telah dihantar. Semak peti masuk anda.',
              ),
              style: TextStyle(color: colors.onPrimary),
            ),
            backgroundColor: colors.primary,
          ),
        );
      }
    });

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: _emailSent
                    ? authCopy(context, 'Check your email', 'Semak e-mel anda')
                    : authCopy(
                        context,
                        'Reset your password',
                        'Tetapkan semula kata laluan anda',
                      ),
                subtitle: _emailSent
                    ? authCopy(
                        context,
                        'Check your email for a password reset link.',
                        'Semak e-mel anda untuk pautan set semula kata laluan.',
                      )
                    : authCopy(
                        context,
                        'Enter the email on your account and we’ll send a link to set a new password.',
                        'Masukkan e-mel pada akaun anda dan kami akan menghantar pautan untuk menetapkan kata laluan baharu.',
                      ),
              ),
              const SizedBox(height: 26),
              if (!_emailSent) ...[
                AuthField(
                  label: authLabel(context, 'auth.email', 'Email'),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: authInputDecoration(
                      context,
                      hintText: authCopy(
                        context,
                        'you@company.com',
                        'anda@syarikat.com',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return authCopy(
                          context,
                          'Please enter your email',
                          'Sila masukkan e-mel anda',
                        );
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return authCopy(
                          context,
                          'Please enter a valid email',
                          'Sila masukkan alamat e-mel yang sah',
                        );
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleResetPassword(),
                  ),
                ),
                const SizedBox(height: 24),
                AuthSubmitButton(
                  onPressed: _handleResetPassword,
                  text: authCopy(
                    context,
                    'Send reset link',
                    'Hantar pautan set semula',
                  ),
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _backToLogin,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      authCopy(
                        context,
                        'Back to login',
                        'Kembali ke log masuk',
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authCopy(
                        context,
                        'We’ve sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.',
                        'Kami telah menghantar pautan set semula kata laluan ke alamat e-mel anda. Semak peti masuk dan ikut arahan untuk menetapkan semula kata laluan anda.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AuthSubmitButton(
                  onPressed: _backToLogin,
                  text: authCopy(
                    context,
                    'Back to login',
                    'Kembali ke log masuk',
                  ),
                  isLoading: false,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _emailSent = false);
                    ref.read(authProvider.notifier).clearError();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(authCopy(context, 'Send again', 'Hantar semula')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_loginRoute);
    }
  }

  void _handleResetPassword() {
    if (ref.read(authProvider).isLoading) return;
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .resetPassword(_emailController.text.trim());
    }
  }
}
