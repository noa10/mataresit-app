import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Auth destinations are kept local, matching the invitation flow, so the
/// screens do not pull the whole app router into their widget tests.
const _dashboardRoute = '/dashboard';
const _registerRoute = '/register';
const _forgotPasswordRoute = '/forgot-password';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).colorScheme;
    final emailLabel = authLabel(context, 'auth.email', 'Email');
    final passwordLabel = authLabel(context, 'auth.password', 'Password');
    final signInLabel = authLabel(context, 'auth.signIn', 'Sign In');
    final signUpLabel = authLabel(context, 'auth.signUp', 'Sign Up');

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: TextStyle(color: colors.onError)),
            backgroundColor: colors.error,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: authLabel(context, 'common.buttons.close', 'Close'),
              textColor: colors.onError,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }

      if (next.isAuthenticated && next.user != null) {
        context.go(_dashboardRoute);
      }
    });

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (context.canPop()) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      authLabel(context, 'common.buttons.back', 'Back'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              AuthHeader(
                title: authCopy(context, 'Log in', 'Log masuk'),
                subtitle: authCopy(
                  context,
                  'Log in to pick up where your receipts left off.',
                  'Log masuk untuk menyambung semula urusan resit anda.',
                ),
              ),
              const SizedBox(height: 26),
              AuthModeSelector(
                isSignIn: true,
                onSignIn: () {},
                onSignUp: () => context.push(_registerRoute),
              ),
              const SizedBox(height: 24),
              AuthField(
                label: emailLabel,
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                ),
              ),
              const SizedBox(height: 18),
              AuthField(
                label: passwordLabel,
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: authInputDecoration(
                    context,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? authCopy(
                              context,
                              'Show password',
                              'Tunjuk kata laluan',
                            )
                          : authCopy(
                              context,
                              'Hide password',
                              'Sembunyi kata laluan',
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return authCopy(
                        context,
                        'Please enter your password',
                        'Sila masukkan kata laluan anda',
                      );
                    }
                    if (value.length < 6) {
                      return authCopy(
                        context,
                        'Password must be at least 6 characters',
                        'Kata laluan mestilah sekurang-kurangnya 6 aksara',
                      );
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSignIn(),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(_forgotPasswordRoute),
                  child: Text(
                    authLabel(
                      context,
                      'auth.forgotPassword',
                      'Forgot Password?',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AuthSubmitButton(
                onPressed: _handleSignIn,
                text: signInLabel,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 22),
              const AuthDivider(),
              const SizedBox(height: 16),
              AuthGoogleButton(
                onPressed: () =>
                    ref.read(authProvider.notifier).signInWithGoogle(),
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 12),
              AuthAccountLink(
                prompt: authLabel(
                  context,
                  'auth.dontHaveAccount',
                  "Don't have an account?",
                ),
                action: signUpLabel,
                onPressed: () => context.push(_registerRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (ref.read(authProvider).isLoading) return;
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }
}
