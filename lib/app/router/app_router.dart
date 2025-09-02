import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/receipts/screens/receipts_screen.dart';
import '../../features/receipts/screens/modern_receipt_detail_screen.dart';
import '../../features/receipts/screens/receipt_capture_screen.dart';
import '../../features/claims/screens/claims_screen.dart';
import '../../features/claims/screens/claim_detail_screen.dart';
import '../../features/teams/screens/teams_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../shared/widgets/main_navigation_wrapper.dart';
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
  static const String claims = '/claims';
  static const String claimDetail = '/claims/:id';
  static const String teams = '/teams';
  static const String settings = '/settings';
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
      
      // Show splash screen while loading
      if (isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      
      // After loading is complete, redirect based on authentication status
      if (!isLoading) {
        // If on splash screen and not loading, redirect based on auth status
        if (location == AppRoutes.splash) {
          return isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
        }
        
        // Redirect to login if not authenticated and trying to access protected routes
        if (!isAuthenticated && !_isPublicRoute(location)) {
          return AppRoutes.login;
        }
        
        // Redirect to dashboard if authenticated and trying to access auth routes
        if (isAuthenticated && _isAuthRoute(location)) {
          return AppRoutes.dashboard;
        }
      }
      
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
        builder: (context, state, child) => MainNavigationWrapper(child: child),
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
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),

      // Debug routes (outside shell for easier access)
      GoRoute(
        path: AppRoutes.debugDatabase,
        builder: (context, state) => const DatabaseDebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
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
