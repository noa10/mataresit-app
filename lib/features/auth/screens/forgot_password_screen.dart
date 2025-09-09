import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/auth_provider.dart';

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

    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }

      if (previous?.isLoading == true &&
          next.isLoading == false &&
          next.error == null) {
        setState(() {
          _emailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.largePadding * 2),

                // Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.largeBorderRadius,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                // Title
                Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Password?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.smallPadding),

                // Description
                Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions to reset your password.'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppConstants.largePadding * 2),

                if (!_emailSent) ...[
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleResetPassword(),
                  ),

                  const SizedBox(height: AppConstants.largePadding * 2),

                  // Reset Password Button
                  LoadingButton(
                    onPressed: _handleResetPassword,
                    text: 'Send Reset Link',
                    isLoading: authState.isLoading,
                  ),
                ] else ...[
                  // Success Actions
                  ElevatedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Login'),
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                      });
                      ref.read(authProvider.notifier).clearError();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Send Again'),
                  ),
                ],

                const SizedBox(height: AppConstants.largePadding),

                // Back to Login
                if (!_emailSent)
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Login'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .resetPassword(_emailController.text.trim());
    }
  }
}
