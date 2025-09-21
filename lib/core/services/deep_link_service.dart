import 'dart:async';
import 'package:app_links/app_links.dart';
import '../network/supabase_client.dart';
import 'app_logger.dart';

/// Service to handle deep links and OAuth callbacks
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static DeepLinkService get instance => _instance;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize the deep link service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning('⚠️ DeepLinkService already initialized');
      return;
    }

    try {
      AppLogger.info('🔗 Initializing DeepLinkService...');

      _appLinks = AppLinks();

      // Listen for incoming links when app is already running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        _handleIncomingLink,
        onError: (error) {
          AppLogger.error('❌ Error in deep link stream: $error');
        },
      );

      // Handle initial link if app was opened via deep link
      try {
        final initialLink = await _appLinks.getInitialLink();
        if (initialLink != null) {
          AppLogger.info('🔗 App opened with initial link: $initialLink');
          await _handleIncomingLink(initialLink);
        }
      } catch (e) {
        AppLogger.warning('⚠️ Could not get initial link: $e');
      }

      _isInitialized = true;
      AppLogger.info('✅ DeepLinkService initialized successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize DeepLinkService: $e');
      rethrow;
    }
  }

  /// Handle incoming deep link
  Future<void> _handleIncomingLink(Uri uri) async {
    try {
      AppLogger.info('🔗 Processing incoming link: $uri');

      final scheme = uri.scheme;
      final host = uri.host;
      final path = uri.path;

      AppLogger.debug(
        '🔗 Link details - scheme: $scheme, host: $host, path: $path',
      );

      // Check if this is an OAuth callback
      if (scheme == 'mataresit' && host == 'login-callback') {
        AppLogger.info('🔐 OAuth callback detected, processing...');
        await _handleOAuthCallback(uri);
      } else {
        AppLogger.info('ℹ️ Non-OAuth deep link received: $uri');
        // Handle other deep links here if needed
      }
    } catch (e) {
      AppLogger.error('❌ Error handling incoming link: $e');
    }
  }

  /// Handle OAuth callback from authentication providers
  Future<void> _handleOAuthCallback(Uri uri) async {
    try {
      AppLogger.info('🔐 Processing OAuth callback: $uri');

      // Convert URI to string for processing
      final urlString = uri.toString();

      // Use SupabaseService to handle the OAuth callback
      final success = await SupabaseService.handleOAuthCallback(urlString);

      if (success) {
        AppLogger.info('✅ OAuth callback processed successfully');
      } else {
        AppLogger.error('❌ OAuth callback processing failed');
      }
    } catch (e) {
      AppLogger.error('❌ Error processing OAuth callback: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    AppLogger.info('🔗 Disposing DeepLinkService...');
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
