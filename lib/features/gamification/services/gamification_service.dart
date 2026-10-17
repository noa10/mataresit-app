import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../models/badge.dart';
import '../models/gamification_json.dart';
import '../models/gamification_profile.dart';
import '../models/leaderboard_entry.dart';
import '../models/mission.dart';

/// Error raised when gamification data cannot be read or normalized.
class GamificationException implements Exception {
  const GamificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Handle for the realtime channels a gamification provider owns.
///
/// The provider keeps the handle and cancels it on dispose.
abstract class GamificationRealtimeSubscription {
  Future<void> cancel();
}

/// Gamification backend contract.
///
/// An interface (rather than a concrete class) so tests can substitute a fake
/// and assert which RPCs are issued — notably that the leaderboard RPC is never
/// called for a user who has not opted in.
///
/// `record_receipt_review` also exists server-side, but it belongs to the receipt
/// review flow and is deliberately not called from here.
abstract class GamificationService {
  /// Reads the user's stats, creating the row server-side on first call.
  Future<GamificationProfile> fetchProfile(String userId);

  /// Records today's login (idempotent per local day) and returns the stats.
  Future<GamificationProfile> recordDailyLogin();

  /// The user's missions, progress only — no grouping, no envelope.
  Future<List<GamificationMission>> fetchMissions();

  /// One leaderboard board. [countryCode] is `'MY'` for Malaysia or `null` for
  /// the global board.
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardMetric metric,
    String? countryCode,
  });

  /// The badge catalogue joined with the user's unlock rows.
  Future<List<BadgeWithStatus>> fetchBadges(String userId);

  /// Persists the leaderboard preferences. Only these columns are written:
  /// `total_xp` is server-owned and `current_level` is a generated column.
  Future<GamificationProfile> updateLeaderboardPreferences({
    required String userId,
    required bool leaderboardOptIn,
    required String leaderboardDisplayMode,
    String? countryCode,
  });

  /// Redeems an invite code. Resolves to `false` when the server rejects the
  /// code (unknown, own, or already redeemed) rather than throwing.
  Future<bool> redeemReferralCode(String referralCode);

  /// Watches the user's gamification rows. [onChange] fires for inserts into
  /// `gamification_xp_events` and any change to `user_badges` or
  /// `user_gamification_stats`.
  GamificationRealtimeSubscription subscribeToChanges({
    required String userId,
    required void Function() onChange,
  });
}

/// Supabase-backed [GamificationService].
class SupabaseGamificationService implements GamificationService {
  SupabaseGamificationService(this._client);

  final SupabaseClient _client;
  final Logger _logger = Logger();

  static const String _statsTable = 'user_gamification_stats';

  @override
  Future<GamificationProfile> fetchProfile(String userId) async {
    try {
      final response = await _client.rpc(
        'ensure_user_gamification_stats',
        params: {'p_user_id': userId},
      );
      final row = GamificationJson.asSingleRow(response);
      if (row != null) return GamificationProfile.fromMap(row);
      _logger.w('ensure_user_gamification_stats returned no row for $userId');
    } catch (e) {
      _logger.w(
        'ensure_user_gamification_stats failed for $userId, '
        'falling back to a direct read: $e',
      );
    }

    final row = await _client
        .from(_statsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) {
      throw const GamificationException(
        'No gamification stats are available for this account yet.',
      );
    }
    return GamificationProfile.fromMap(row);
  }

  @override
  Future<GamificationProfile> recordDailyLogin() async {
    final response = await _client.rpc('record_daily_login');
    final row = GamificationJson.asSingleRow(response);
    if (row == null) {
      throw const GamificationException(
        'record_daily_login did not return a stats row.',
      );
    }
    return GamificationProfile.fromMap(row);
  }

  @override
  Future<List<GamificationMission>> fetchMissions() async {
    // Calling this RPC mutates state (it can award XP), so callers must treat it
    // as a deliberate refresh rather than a build-time read.
    final response = await _client.rpc('get_gamification_missions');
    final rows = GamificationJson.asRows(
      response,
      source: 'get_gamification_missions',
    );

    final missions = <GamificationMission>[];
    var skipped = 0;
    for (final row in rows) {
      if (GamificationJson.pick(row, 'mission') == null) {
        skipped++;
        continue;
      }
      missions.add(GamificationMission.fromMap(row));
    }
    if (skipped > 0) {
      _logger.w(
        'get_gamification_missions returned $skipped rows without a mission',
      );
    }
    return missions;
  }

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardMetric metric,
    String? countryCode,
  }) async {
    final response = await _client.rpc(
      'get_gamification_leaderboard',
      params: {
        '_metric': metric.rpcValue,
        '_country_code': countryCode,
        '_limit': leaderboardMaxLimit,
      },
    );
    return LeaderboardResult.fromRows(
      metric: metric,
      rows: GamificationJson.asRows(
        response,
        source: 'get_gamification_leaderboard',
      ),
    ).entries;
  }

  @override
  Future<List<BadgeWithStatus>> fetchBadges(String userId) async {
    // No joined view and no RPC exist for badges: read the catalogue and the
    // user's unlock rows separately, then join them client-side by badge id.
    final definitionRows = await _client
        .from('gamification_badges')
        .select('*')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    final userRows = await _client
        .from('user_badges')
        .select('*')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return BadgeCollection.join(
      definitions: definitionRows.map(GamificationBadge.fromMap).toList(),
      userBadges: userRows.map(UserBadge.fromMap).toList(),
    );
  }

  @override
  Future<GamificationProfile> updateLeaderboardPreferences({
    required String userId,
    required bool leaderboardOptIn,
    required String leaderboardDisplayMode,
    String? countryCode,
  }) async {
    // Only the preference columns are written: `total_xp` is server-owned and
    // `current_level` is a generated column, so writing either would fail or
    // corrupt the leaderboard.
    final payload = <String, dynamic>{
      'user_id': userId,
      'leaderboard_opt_in': leaderboardOptIn,
      'leaderboard_display_mode': leaderboardDisplayMode,
    };
    if (countryCode != null) payload['country_code'] = countryCode;

    final row = await _client
        .from(_statsTable)
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();
    return GamificationProfile.fromMap(row);
  }

  @override
  Future<bool> redeemReferralCode(String referralCode) async {
    final response = await _client.rpc(
      'redeem_referral_code',
      params: {'p_referral_code': referralCode},
    );
    // The RPC answers with a boolean; most rejections are `false`, not errors.
    return response == true;
  }

  @override
  GamificationRealtimeSubscription subscribeToChanges({
    required String userId,
    required void Function() onChange,
  }) {
    // `SupabaseService.subscribeToTable` cannot be used here: it parses a
    // `column=eq.value` string and passes `eq.value` as the filter value, which
    // realtime_client renders as `column=eq.eq.value` (realtime_client 2.5.2,
    // PostgresChangeFilter.toString). Channels are built directly instead, so
    // the filter value is the bare user id.
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    );

    final channels = <RealtimeChannel>[
      _client.channel('gamification:xp_events:$userId'),
      _client.channel('gamification:badges:$userId'),
      _client.channel('gamification:stats:$userId'),
    ];

    channels[0].onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'gamification_xp_events',
      filter: filter,
      callback: (_) => onChange(),
    );
    channels[1].onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'user_badges',
      filter: filter,
      callback: (_) => onChange(),
    );
    channels[2].onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: _statsTable,
      filter: filter,
      callback: (_) => onChange(),
    );

    for (final channel in channels) {
      channel.subscribe();
    }

    return _SupabaseRealtimeSubscription(_client, channels);
  }
}

class _SupabaseRealtimeSubscription
    implements GamificationRealtimeSubscription {
  _SupabaseRealtimeSubscription(this._client, this._channels);

  final SupabaseClient _client;
  final List<RealtimeChannel> _channels;

  @override
  Future<void> cancel() async {
    for (final channel in _channels) {
      await _client.removeChannel(channel);
    }
  }
}

/// Provider for the gamification service. Overridden in tests with a fake.
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return SupabaseGamificationService(SupabaseService.client);
});
