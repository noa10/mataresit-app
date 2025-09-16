import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/app_logger.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/receipts/screens/receipts_screen.dart';
import '../../features/receipts/screens/modern_receipt_detail_screen.dart';
import '../../features/receipts/screens/receipt_capture_screen.dart';
import '../../features/receipts/screens/batch_upload_screen.dart';
import '../../features/claims/screens/claims_screen.dart';
import '../../features/claims/screens/claim_detail_screen.dart';
import '../../features/teams/screens/teams_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/security/screens/security_settings_screen.dart';
import '../../features/security/screens/password_change_screen.dart';
import '../../features/security/screens/two_factor_auth_screen.dart';
import '../../features/security/screens/session_management_screen.dart';
import '../../features/security/screens/privacy_controls_screen.dart';
import '../../features/security/screens/account_deletion_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/subscription/screens/pricing_screen.dart';
import '../../features/subscription/screens/billing_screen.dart';
import '../../features/settings/screens/language_selection_screen.dart';
import '../../features/settings/screens/currency_settings_screen.dart';
import '../../features/settings/screens/theme_settings_screen.dart';
import '../../features/settings/screens/help_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../shared/widgets/adaptive_navigation_wrapper.dart';
import '../../shared/widgets/splash_screen.dart';
import '../../debug/database_debug_screen.dart';

/// App routes
class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String receipts = '/receipts';
  static const String receiptDetail = '/receipts/:id';
  static const String receiptCapture = '/receipts/capture';
  static const String batchUpload = '/receipts/batch-upload';
  static const String claims = '/claims';
  static const String claimDetail = '/claims/:id';
  static const String teams = '/teams';
  static const String settings = '/settings';
  static const String securitySettings = '/settings/security';
  static const String passwordChange = '/settings/security/password';
  static const String twoFactorAuth = '/settings/security/2fa';
  static const String sessionManagement = '/settings/security/sessions';
  static const String privacyControls = '/settings/security/privacy';
  static const String accountDeletion = '/settings/security/delete-account';
  static const String help = '/help';
  static const String privacyPolicy = '/privacy-policy';
  static const String profile = '/profile';
  static const String analytics = '/analytics';

  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminReceipts = '/admin/receipts';
  static const String adminAnalytics = '/admin/analytics';

  // Debug routes
  static const String debugDatabase = '/debug/database';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final location = state.uri.path;

      AppLogger.debug(
        '🔍 ROUTER DEBUG: location=$location, isLoading=$isLoading, isAuthenticated=$isAuthenticated',
      );

      // Show splash screen while loading
      if (isLoading) {
        AppLogger.debug('🔍 ROUTER: Showing splash screen (loading)');
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // After loading is complete, redirect based on authentication status
      if (!isLoading) {
        // If on splash screen and not loading, redirect based on auth status
        if (location == AppRoutes.splash) {
          final redirectTo = isAuthenticated
              ? AppRoutes.dashboard
              : AppRoutes.login;
          AppLogger.debug('🔍 ROUTER: Redirecting from splash to $redirectTo');
          return redirectTo;
        }

        // Redirect to login if not authenticated and trying to access protected routes
        if (!isAuthenticated && !_isPublicRoute(location)) {
          AppLogger.debug(
            '🔍 ROUTER: Redirecting to login (not authenticated)',
          );
          return AppRoutes.login;
        }

        // Redirect to dashboard if authenticated and trying to access auth routes
        if (isAuthenticated && _isAuthRoute(location)) {
          AppLogger.debug(
            '🔍 ROUTER: Redirecting to dashboard (authenticated)',
          );
          return AppRoutes.dashboard;
        }
      }

      AppLogger.debug('🔍 ROUTER: No redirect needed');
      return null;
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) => AdaptiveNavigationWrapper(
          key: const ValueKey('main_navigation_wrapper'),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.receipts,
            builder: (context, state) => const ReceiptsScreen(),
            routes: [
              GoRoute(
                path: 'capture',
                builder: (context, state) => const ReceiptCaptureScreen(),
              ),
              GoRoute(
                path: 'batch-upload',
                builder: (context, state) => const BatchUploadScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final receiptId = state.pathParameters['id']!;
                  return ModernReceiptDetailScreen(receiptId: receiptId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.claims,
            builder: (context, state) => const ClaimsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final claimId = state.pathParameters['id']!;
                  return ClaimDetailScreen(claimId: claimId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.teams,
            builder: (context, state) => const TeamsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'language',
                builder: (context, state) => const LanguageSelectionScreen(),
              ),
              GoRoute(
                path: 'currency',
                builder: (context, state) => const CurrencySettingsScreen(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeSettingsScreen(),
              ),
              GoRoute(
                path: 'security',
                builder: (context, state) => const SecuritySettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'password',
                    builder: (context, state) => const PasswordChangeScreen(),
                  ),
                  GoRoute(
                    path: '2fa',
                    builder: (context, state) => const TwoFactorAuthScreen(),
                  ),
                  GoRoute(
                    path: 'sessions',
                    builder: (context, state) =>
                        const SessionManagementScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyControlsScreen(),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    builder: (context, state) => const AccountDeletionScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),

      // Subscription routes (outside shell for easier access)
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingScreen(),
      ),

      // Help and Privacy routes (outside shell for easier access)
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // Debug routes (outside shell for easier access)
      GoRoute(
        path: AppRoutes.debugDatabase,
        builder: (context, state) => const DatabaseDebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Check if route is public (doesn't require authentication)
bool _isPublicRoute(String location) {
  const publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  ];
  return publicRoutes.contains(location);
}

/// Check if route is an auth route
bool _isAuthRoute(String location) {
  const authRoutes = [
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  ];
  return authRoutes.contains(location);
}
