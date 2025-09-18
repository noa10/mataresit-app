import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';

/// Supabase client configuration and initialization
class SupabaseService {
  static final Logger _logger = Logger();
  static SupabaseClient? _client;
  static bool _isInitializing = false;
  static bool _initializationCompleted = false;
  static Completer<void>? _initializationCompleter;

  /// Initialize Supabase with retry logic and better error handling
  static Future<void> initialize() async {
    if (_isInitializing) {
      _logger.w('Supabase initialization already in progress, waiting...');
      // Wait for the existing initialization to complete
      if (_initializationCompleter != null) {
        await _initializationCompleter!.future;
      }
      return;
    }

    if (_initializationCompleted && _client != null) {
      _logger.i('Supabase already initialized');
      return;
    }

    _isInitializing = true;
    _initializationCompleter = Completer<void>();

    try {
      _logger.i('Starting Supabase initialization...');

      // Check if Supabase is already initialized to prevent duplicate initialization
      try {
        final existingClient = Supabase.instance.client;
        _logger.i('Supabase already initialized, using existing instance');
        _client = existingClient;
        _initializationCompleted = true;
        _logger.i('✅ Supabase initialization completed (existing instance)');
        return;
      } catch (e) {
        _logger.d(
          'Supabase not yet initialized, proceeding with initialization: $e',
        );
      }

      // Try to initialize Supabase with retry logic for iOS 18.x beta compatibility
      int initRetryCount = 0;
      const maxInitRetries = 3;
      Exception? lastException;

      while (initRetryCount < maxInitRetries) {
        try {
          await Supabase.initialize(
            url: AppConstants.supabaseUrl,
            anonKey: AppConstants.supabaseAnonKey,
            debug: true,
            realtimeClientOptions: const RealtimeClientOptions(
              // heartbeatIntervalMs: AppConstants.realtimeHeartbeatInterval,
              // reconnectDelay: Duration(seconds: 2),
              // timeoutMs: 20000,
            ),
          );
          _logger.i('Supabase.initialize() completed successfully');
          break; // Success, exit retry loop
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          initRetryCount++;

          // Check if this is a SharedPreferences channel error
          if (e.toString().contains('channel-error') &&
              e.toString().contains('LegacyUserDefaultsApi')) {
            _logger.w(
              'Supabase initialization failed due to iOS 18.x beta SharedPreferences issue (attempt $initRetryCount/$maxInitRetries): $e',
            );

            if (initRetryCount < maxInitRetries) {
              final retryDelay = Duration(milliseconds: 500 * initRetryCount);
              _logger.i(
                'Retrying Supabase initialization in ${retryDelay.inMilliseconds}ms...',
              );
              await Future.delayed(retryDelay);
            }
          } else {
            _logger.e(
              'Supabase initialization failed with non-SharedPreferences error: $e',
            );
            rethrow; // Re-throw non-SharedPreferences errors immediately
          }
        }
      }

      // If all retries failed, throw the last exception
      if (initRetryCount >= maxInitRetries && lastException != null) {
        _logger.e(
          'Supabase initialization failed after $maxInitRetries attempts',
        );
        throw lastException;
      }

      // Ensure client is available with retry logic
      int retryCount = 0;
      const maxRetries = 5;
      const retryDelay = Duration(milliseconds: 200);

      while (retryCount < maxRetries) {
        try {
          _client = Supabase.instance.client;
          if (_client != null) {
            _logger.i('Supabase client successfully obtained');
            break;
          }
        } catch (e) {
          _logger.w(
            'Attempt ${retryCount + 1} to get Supabase client failed: $e',
          );
        }

        retryCount++;
        if (retryCount < maxRetries) {
          _logger.i(
            'Retrying to get Supabase client in ${retryDelay.inMilliseconds}ms...',
          );
          await Future.delayed(retryDelay);
        }
      }

      if (_client == null) {
        throw Exception(
          'Failed to obtain Supabase client after $maxRetries attempts',
        );
      }

      _initializationCompleted = true;
      _logger.i('✅ Supabase initialization completed successfully');

      // Complete the initialization future
      if (_initializationCompleter != null &&
          !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.complete();
      }
    } catch (e) {
      _logger.e('❌ Supabase initialization failed: $e');
      _initializationCompleted = false;
      _client = null;

      // Complete the initialization future with error
      if (_initializationCompleter != null &&
          !_initializationCompleter!.isCompleted) {
        _initializationCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Wait for Supabase initialization to complete
  static Future<void> waitForInitialization() async {
    if (_initializationCompleted && _client != null) {
      return; // Already initialized
    }

    if (_initializationCompleter != null) {
      await _initializationCompleter!.future;
    }
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _initializationCompleted && _client != null;

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (!isInitialized || _client == null) {
      _logger.e(
        'Supabase client requested but not initialized. isInitialized: $isInitialized, _client: ${_client != null}',
      );
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current session
  static Session? get currentSession => client.auth.currentSession;

  /// Get auth state stream
  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Update user
  static Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.updateUser(
      UserAttributes(email: email, password: password, data: data),
    );
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Create user profile
  static Future<Map<String, dynamic>?> createUserProfile({
    required String userId,
    String? email,
    String? firstName,
    String? lastName,
    String? googleAvatarUrl,
    String? preferredLanguage,
  }) async {
    final profileData = {
      'id': userId,
      'email': email,
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      'google_avatar_url': googleAvatarUrl,
      'preferred_language': preferredLanguage ?? 'en',
      'subscription_tier': 'free',
      'subscription_status': 'active',
      'receipts_used_this_month': 0,
      'monthly_reset_date': DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('profiles')
        .insert(profileData)
        .select()
        .single();

    return response;
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateUserProfile({
    required String userId,
    Map<String, dynamic>? updates,
  }) async {
    if (updates == null || updates.isEmpty) return null;

    final updateData = {
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('profiles')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return response;
  }

  /// Upload file to storage
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final logger = Logger();

    try {
      logger.i('Starting storage upload:');
      logger.i('  Bucket: $bucket');
      logger.i('  Path: $path');
      logger.i(
        '  Size: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)',
      );
      logger.i('  Content-Type: $contentType');

      // Use upsert: false to match React app behavior and avoid conflicts
      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false, // Match React app behavior
              cacheControl: '3600', // Match React app cache control
            ),
          );

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      logger.i('Storage upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      // Enhanced error handling for storage uploads
      if (e.toString().contains('Duplicate') ||
          e.toString().contains('already exists')) {
        // If file already exists, try with upsert: true as fallback
        try {
          await client.storage
              .from(bucket)
              .uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: true,
                  cacheControl: '3600',
                ),
              );
          return client.storage.from(bucket).getPublicUrl(path);
        } catch (upsertError) {
          throw Exception(
            'Storage upload failed even with upsert: ${upsertError.toString()}',
          );
        }
      }

      // Provide more specific error messages
      String errorMessage = 'Storage upload failed';
      if (e.toString().contains('bucket not found')) {
        errorMessage = 'Storage bucket not found. Please contact support.';
      } else if (e.toString().contains('row-level security') ||
          e.toString().contains('policy')) {
        errorMessage = 'Permission denied. Please log in again.';
      } else if (e.toString().contains('413') ||
          e.toString().contains('too large')) {
        errorMessage = 'File too large. Please use a smaller image.';
      } else if (e.toString().contains('400')) {
        errorMessage =
            'Invalid file or request. Please try again with a different image.';
      } else {
        errorMessage = 'Storage upload failed: ${e.toString()}';
      }

      throw Exception(errorMessage);
    }
  }

  /// Delete file from storage
  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await client.storage.from(bucket).remove([path]);
  }

  /// Get public URL for file
  static String getPublicUrl({required String bucket, required String path}) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Subscribe to real-time changes
  static RealtimeChannel subscribeToTable({
    required String table,
    String? filter,
    void Function(PostgresChangePayload)? onInsert,
    void Function(PostgresChangePayload)? onUpdate,
    void Function(PostgresChangePayload)? onDelete,
  }) {
    final channel = client.channel('public:$table');

    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filter.split('=')[0],
                value: filter.split('=')[1],
              )
            : null,
        callback: onInsert,
      );
    }

    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filter.split('=')[0],
                value: filter.split('=')[1],
              )
            : null,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        filter: filter != null
            ? PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filter.split('=')[0],
                value: filter.split('=')[1],
              )
            : null,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from real-time channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  /// Execute RPC function
  static Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    return await client.rpc(functionName, params: params);
  }
}

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseService.isInitialized) {
    throw Exception(
      'Supabase not initialized. Please wait for initialization to complete.',
    );
  }
  return SupabaseService.client;
});
