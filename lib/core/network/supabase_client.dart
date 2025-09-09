import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Supabase client configuration and initialization
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
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
    _client = Supabase.instance.client;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
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
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return client.storage.from(bucket).getPublicUrl(path);
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
  return SupabaseService.client;
});
