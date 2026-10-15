import 'package:flutter_test/flutter_test.dart';
import 'package:mataresit_app/features/gamification/models/gamification_profile.dart';

void main() {
  GamificationProfile profile({int totalXp = 0, int level = 1}) {
    return GamificationProfile(
      userId: 'user-1',
      totalXp: totalXp,
      currentLevel: level,
    );
  }

  group('XP/level arithmetic', () {
    test('starts the first level at zero progress', () {
      final fresh = profile();

      expect(fresh.xpFloor, 0);
      expect(fresh.xpIntoLevel, 0);
      expect(fresh.progressPercent, 0);
      expect(fresh.xpToNextLevel, 500);
    });

    test('reports partial progress inside a level', () {
      final halfway = profile(totalXp: 250, level: 1);

      expect(halfway.xpIntoLevel, 250);
      expect(halfway.progressPercent, 50);
      expect(halfway.xpToNextLevel, 250);
    });

    test('subtracts the XP floor for levels above the first', () {
      final levelThree = profile(totalXp: 1250, level: 3);

      expect(levelThree.xpFloor, 1000);
      expect(levelThree.xpIntoLevel, 250);
      expect(levelThree.progressPercent, 50);
      expect(levelThree.xpToNextLevel, 250);
    });

    test('a level boundary reads as the start of the new level', () {
      final boundary = profile(totalXp: 1000, level: 3);

      expect(boundary.xpFloor, 1000);
      expect(boundary.xpIntoLevel, 0);
      expect(boundary.progressPercent, 0);
      expect(boundary.xpToNextLevel, 500);
    });

    test('one XP short of the next level is 99.8 percent', () {
      final almost = profile(totalXp: 499, level: 1);

      expect(almost.xpIntoLevel, 499);
      expect(almost.progressPercent, closeTo(99.8, 0.001));
    });

    test('clamps at 100 percent when the stored level lags the XP', () {
      final stale = profile(totalXp: 5000, level: 1);

      expect(stale.xpIntoLevel, 5000);
      expect(stale.progressPercent, 100);
      expect(stale.xpToNextLevel, 0);
    });

    test('clamps at 0 percent when the stored level leads the XP', () {
      final ahead = profile(totalXp: 100, level: 5);

      expect(ahead.xpFloor, 2000);
      expect(ahead.xpIntoLevel, 0);
      expect(ahead.progressPercent, 0);
      expect(ahead.xpToNextLevel, 500);
    });

    test('levelForXp mirrors the server formula', () {
      expect(GamificationProfile.levelForXp(0), 1);
      expect(GamificationProfile.levelForXp(499), 1);
      expect(GamificationProfile.levelForXp(500), 2);
      expect(GamificationProfile.levelForXp(1000), 3);
      expect(GamificationProfile.levelForXp(2499), 5);
    });

    test('derives the level when the payload has no current_level', () {
      final parsed = GamificationProfile.fromMap({
        'user_id': 'user-1',
        'total_xp': 1500,
      });

      expect(parsed.currentLevel, 4);
      expect(parsed.xpIntoLevel, 0);
    });

    test('prefers the server level over the derived one', () {
      final parsed = GamificationProfile.fromMap({
        'user_id': 'user-1',
        'total_xp': 1500,
        'current_level': 7,
      });

      expect(parsed.currentLevel, 7);
      expect(parsed.xpFloor, 3000);
    });
  });

  group('payload parsing', () {
    test('reads the stats row including preferences and referral', () {
      final parsed = GamificationProfile.fromMap({
        'user_id': 'user-1',
        'total_xp': 320,
        'current_level': 1,
        'login_streak_days': 4,
        'scan_streak_days': 2,
        'longest_login_streak_days': 9,
        'longest_scan_streak_days': 5,
        'last_login_date': '2026-10-15',
        'last_scan_date': '2026-10-14',
        'total_receipts_scanned': 12,
        'deductible_receipt_count': 3,
        'deductible_total_amount': 250.5,
        'leaderboard_opt_in': true,
        'leaderboard_display_mode': 'name',
        'country_code': 'MY',
        'referral_code': 'MATA-1234',
        'successful_referrals': 2,
      });

      expect(parsed.totalXp, 320);
      expect(parsed.loginStreakDays, 4);
      expect(parsed.scanStreakDays, 2);
      expect(parsed.longestLoginStreakDays, 9);
      expect(parsed.longestScanStreakDays, 5);
      expect(parsed.totalReceiptsScanned, 12);
      expect(parsed.deductibleReceiptCount, 3);
      expect(parsed.deductibleTotalAmount, 250.5);
      expect(parsed.leaderboardOptIn, isTrue);
      expect(parsed.showsNameOnLeaderboard, isTrue);
      expect(parsed.countryCode, 'MY');
      expect(parsed.referralCode, 'MATA-1234');
      expect(parsed.successfulReferrals, 2);
    });

    test('defaults to anonymous and opted out', () {
      final parsed = GamificationProfile.fromMap({'user_id': 'user-1'});

      expect(parsed.leaderboardOptIn, isFalse);
      expect(
        parsed.leaderboardDisplayMode,
        GamificationProfile.displayModeAnonymous,
      );
      expect(parsed.showsNameOnLeaderboard, isFalse);
      expect(parsed.countryCode, 'MY');
    });

    test('coerces numeric strings and nulls', () {
      final parsed = GamificationProfile.fromMap({
        'user_id': 'user-1',
        'total_xp': '640',
        'current_level': '2',
        'deductible_total_amount': '99.99',
        'referral_code': null,
      });

      expect(parsed.totalXp, 640);
      expect(parsed.currentLevel, 2);
      expect(parsed.deductibleTotalAmount, 99.99);
      expect(parsed.referralCode, isNull);
    });
  });

  group('daily goal', () {
    test('is complete when the last scan is today in the profile timezone', () {
      // 20:00 UTC on 14 Oct is 04:00 on 15 Oct in Asia/Kuala_Lumpur.
      final now = DateTime.utc(2026, 10, 14, 20);
      final scanned = GamificationProfile(
        userId: 'user-1',
        currentLevel: 1,
        lastScanDate: DateTime(2026, 10, 15),
      );

      expect(scanned.isDailyGoalCompleted(now: now), isTrue);
      expect(scanned.localDateKey(now: now), '2026-10-15');
    });

    test('is incomplete when the last scan was yesterday locally', () {
      final now = DateTime.utc(2026, 10, 14, 20);
      final scannedYesterday = GamificationProfile(
        userId: 'user-1',
        currentLevel: 1,
        lastScanDate: DateTime(2026, 10, 14),
      );

      expect(scannedYesterday.isDailyGoalCompleted(now: now), isFalse);
    });

    test('is incomplete when nothing has been scanned', () {
      final never = GamificationProfile(userId: 'user-1', currentLevel: 1);

      expect(
        never.isDailyGoalCompleted(now: DateTime.utc(2026, 10, 15, 2)),
        isFalse,
      );
    });
  });
}
