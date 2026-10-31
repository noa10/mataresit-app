import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

const _dashboardRoute = '/dashboard';
const _loginRoute = '/login';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).colorScheme;
    final signInLabel = authLabel(context, 'auth.signIn', 'Sign In');
    final emailLabel = authLabel(context, 'auth.email', 'Email');
    final passwordLabel = authLabel(context, 'auth.password', 'Password');

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!, style: TextStyle(color: colors.onError)),
            backgroundColor: colors.error,
          ),
        );
      }

      if (next.isAuthenticated) {
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(
                    authLabel(context, 'common.buttons.back', 'Back'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthHeader(
                title: authCopy(context, 'Create account', 'Cipta akaun'),
                subtitle: authCopy(
                  context,
                  'Create an account and start filing receipts in minutes.',
                  'Cipta akaun dan mula memfailkan resit dalam beberapa minit.',
                ),
              ),
              const SizedBox(height: 26),
              AuthModeSelector(
                isSignIn: false,
                onSignIn: _goToLogin,
                onSignUp: () {},
              ),
              const SizedBox(height: 24),
              AuthField(
                label: authCopy(context, 'Full name', 'Nama penuh'),
                child: TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: authInputDecoration(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return authCopy(
                        context,
                        'Please enter your full name',
                        'Sila masukkan nama penuh anda',
                      );
                    }
                    if (value.length < 2) {
                      return authCopy(
                        context,
                        'Name must be at least 2 characters',
                        'Nama mestilah sekurang-kurangnya 2 aksara',
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
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
                    if (value.length < AppConstants.minPasswordLength) {
                      return authCopy(
                        context,
                        'Password must be at least ${AppConstants.minPasswordLength} characters',
                        'Kata laluan mestilah sekurang-kurangnya ${AppConstants.minPasswordLength} aksara',
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 18),
              AuthField(
                label: authLabel(
                  context,
                  'auth.confirmPassword',
                  'Confirm Password',
                ),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: authInputDecoration(
                    context,
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
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
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return authCopy(
                        context,
                        'Please confirm your password',
                        'Sila sahkan kata laluan anda',
                      );
                    }
                    if (value != _passwordController.text) {
                      return authCopy(
                        context,
                        'Passwords do not match',
                        'Kata laluan tidak sepadan',
                      );
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleRegister(),
                ),
              ),
              const SizedBox(height: 24),
              AuthSubmitButton(
                onPressed: _handleRegister,
                text: authLabel(
                  context,
                  'auth.createAccount',
                  'Create Account',
                ),
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
                  'auth.alreadyHaveAccount',
                  'Already have an account?',
                ),
                action: signInLabel,
                onPressed: _goToLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_loginRoute);
    }
  }

  void _goToLogin() {
    // Registration may be opened from an invitation instead of login.
    final matches = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.matches;
    if (matches.length > 1 &&
        matches[matches.length - 2].matchedLocation == _loginRoute) {
      context.pop();
    } else {
      context.push(_loginRoute);
    }
  }

  void _handleRegister() {
    if (ref.read(authProvider).isLoading) return;
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .signUpWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
          );
    }
  }
}
