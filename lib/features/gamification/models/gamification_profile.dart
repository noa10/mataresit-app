import 'dart:math' as math;

import 'gamification_json.dart';

/// XP required to advance one level. Mirrors the server-side formula behind the
/// `current_level` generated column of `user_gamification_stats`.
const int xpPerLevel = 500;

/// Timezone used for the daily-goal check when the caller does not pass one.
const String defaultGamificationTimezone = 'Asia/Kuala_Lumpur';

/// The `user_gamification_stats` row for the signed-in user.
///
/// `current_level` is a generated stored column on the server: it is read from
/// the payload and only computed locally as a fallback when the server omits it.
class GamificationProfile {
  const GamificationProfile({
    required this.userId,
    this.totalXp = 0,
    required this.currentLevel,
    this.loginStreakDays = 0,
    this.scanStreakDays = 0,
    this.longestLoginStreakDays = 0,
    this.longestScanStreakDays = 0,
    this.lastLoginDate,
    this.lastScanDate,
    this.totalReceiptsScanned = 0,
    this.deductibleReceiptCount = 0,
    this.deductibleTotalAmount = 0,
    this.leaderboardOptIn = false,
    this.leaderboardDisplayMode = displayModeAnonymous,
    this.countryCode = 'MY',
    this.referralCode,
    this.successfulReferrals = 0,
    this.selectedScannerTheme = 'default',
    this.unlockedScannerThemes = const <String>[],
  });

  /// `leaderboard_display_mode` values accepted by the server.
  static const String displayModeAnonymous = 'anonymous';
  static const String displayModeName = 'name';

  /// Fixed UTC offsets for the timezones this app supports.
  ///
  /// The app ships no IANA timezone database, and Malaysia (the default and the
  /// only market the profile timezone is used for) has no daylight saving, so a
  /// fixed offset is exact. Unknown zones fall back to [_fallbackOffset].
  static const Map<String, Duration> _timezoneOffsets = {
    'Asia/Kuala_Lumpur': Duration(hours: 8),
    'Asia/Singapore': Duration(hours: 8),
    'Asia/Brunei': Duration(hours: 8),
    'UTC': Duration.zero,
    'Etc/UTC': Duration.zero,
  };
  static const Duration _fallbackOffset = Duration(hours: 8);

  final String userId;
  final int totalXp;

  /// Server-generated level; falls back to [levelForXp] when the payload omits
  /// `current_level`.
  final int currentLevel;

  final int loginStreakDays;
  final int scanStreakDays;
  final int longestLoginStreakDays;
  final int longestScanStreakDays;
  final DateTime? lastLoginDate;
  final DateTime? lastScanDate;
  final int totalReceiptsScanned;
  final int deductibleReceiptCount;
  final double deductibleTotalAmount;
  final bool leaderboardOptIn;
  final String leaderboardDisplayMode;
  final String countryCode;
  final String? referralCode;
  final int successfulReferrals;
  final String selectedScannerTheme;
  final List<String> unlockedScannerThemes;

  factory GamificationProfile.fromMap(Map<String, dynamic> map) {
    return GamificationProfile(
      userId: GamificationJson.stringOr(GamificationJson.pick(map, 'user_id')),
      totalXp: GamificationJson.asInt(GamificationJson.pick(map, 'total_xp')),
      currentLevel: _levelFromMap(map),
      loginStreakDays: GamificationJson.asInt(
        GamificationJson.pick(map, 'login_streak_days'),
      ),
      scanStreakDays: GamificationJson.asInt(
        GamificationJson.pick(map, 'scan_streak_days'),
      ),
      longestLoginStreakDays: GamificationJson.asInt(
        GamificationJson.pick(map, 'longest_login_streak_days'),
      ),
      longestScanStreakDays: GamificationJson.asInt(
        GamificationJson.pick(map, 'longest_scan_streak_days'),
      ),
      lastLoginDate: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'last_login_date'),
      ),
      lastScanDate: GamificationJson.asDateTime(
        GamificationJson.pick(map, 'last_scan_date'),
      ),
      totalReceiptsScanned: GamificationJson.asInt(
        GamificationJson.pick(map, 'total_receipts_scanned'),
      ),
      deductibleReceiptCount: GamificationJson.asInt(
        GamificationJson.pick(map, 'deductible_receipt_count'),
      ),
      deductibleTotalAmount: GamificationJson.asDouble(
        GamificationJson.pick(map, 'deductible_total_amount'),
      ),
      leaderboardOptIn: GamificationJson.asBool(
        GamificationJson.pick(map, 'leaderboard_opt_in'),
      ),
      leaderboardDisplayMode: GamificationJson.stringOr(
        GamificationJson.pick(map, 'leaderboard_display_mode'),
        displayModeAnonymous,
      ),
      countryCode: GamificationJson.stringOr(
        GamificationJson.pick(map, 'country_code'),
        'MY',
      ),
      referralCode: GamificationJson.asString(
        GamificationJson.pick(map, 'referral_code'),
      ),
      successfulReferrals: GamificationJson.asInt(
        GamificationJson.pick(map, 'successful_referrals'),
      ),
      selectedScannerTheme: GamificationJson.stringOr(
        GamificationJson.pick(map, 'selected_scanner_theme'),
        'default',
      ),
      unlockedScannerThemes: GamificationJson.asStringList(
        GamificationJson.pick(map, 'unlocked_scanner_themes'),
      ),
    );
  }

  /// Level implied by [totalXp] — mirrors the server formula. Used only when the
  /// payload carries no `current_level`.
  static int levelForXp(int totalXp) => (totalXp ~/ xpPerLevel) + 1;

  static int _levelFromMap(Map<String, dynamic> map) {
    final raw = GamificationJson.pick(map, 'current_level');
    if (raw == null) {
      return levelForXp(
        GamificationJson.asInt(GamificationJson.pick(map, 'total_xp')),
      );
    }
    final level = GamificationJson.asInt(raw);
    return level < 1 ? 1 : level;
  }

  /// XP accumulated before the current level started.
  int get xpFloor => math.max(0, (currentLevel - 1) * xpPerLevel);

  /// XP earned inside the current level.
  int get xpIntoLevel => math.max(0, totalXp - xpFloor);

  /// XP still missing to reach the next level.
  int get xpToNextLevel => math.max(0, xpPerLevel - xpIntoLevel);

  /// Progress through the current level, 0-100.
  double get progressPercent =>
      (xpIntoLevel / xpPerLevel * 100).clamp(0, 100).toDouble();

  /// `true` when the leaderboard shows the user's name rather than a masked one.
  bool get showsNameOnLeaderboard => leaderboardDisplayMode == displayModeName;

  /// `true` when the user has already scanned a receipt today in [timezone].
  bool isDailyGoalCompleted({
    DateTime? now,
    String timezone = defaultGamificationTimezone,
  }) {
    final lastScan = lastScanDate;
    if (lastScan == null) return false;
    return _dateKeyInTimezone(now ?? DateTime.now(), timezone) ==
        _dateKey(lastScan);
  }

  /// `YYYY-MM-DD` of [date] in [timezone].
  String localDateKey({
    DateTime? now,
    String timezone = defaultGamificationTimezone,
  }) => _dateKeyInTimezone(now ?? DateTime.now(), timezone);

  static String _dateKeyInTimezone(DateTime now, String timezone) {
    final offset = _timezoneOffsets[timezone] ?? _fallbackOffset;
    return _dateKey(now.toUtc().add(offset));
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }

  GamificationProfile copyWith({
    int? totalXp,
    int? currentLevel,
    bool? leaderboardOptIn,
    String? leaderboardDisplayMode,
    String? countryCode,
    String? referralCode,
    int? successfulReferrals,
  }) {
    return GamificationProfile(
      userId: userId,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      loginStreakDays: loginStreakDays,
      scanStreakDays: scanStreakDays,
      longestLoginStreakDays: longestLoginStreakDays,
      longestScanStreakDays: longestScanStreakDays,
      lastLoginDate: lastLoginDate,
      lastScanDate: lastScanDate,
      totalReceiptsScanned: totalReceiptsScanned,
      deductibleReceiptCount: deductibleReceiptCount,
      deductibleTotalAmount: deductibleTotalAmount,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      leaderboardDisplayMode:
          leaderboardDisplayMode ?? this.leaderboardDisplayMode,
      countryCode: countryCode ?? this.countryCode,
      referralCode: referralCode ?? this.referralCode,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      selectedScannerTheme: selectedScannerTheme,
      unlockedScannerThemes: unlockedScannerThemes,
    );
  }
}
