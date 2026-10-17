import 'gamification_json.dart';

/// Metrics accepted by `get_gamification_leaderboard`. The server raises an
/// exception for anything else, so the enum is the only way to build a query.
enum LeaderboardMetric {
  weeklyXp('weekly_xp'),
  monthlyReceipts('monthly_receipts'),
  deductibleTotal('deductible_total');

  const LeaderboardMetric(this.rpcValue);

  /// The `_metric` argument sent to the RPC.
  final String rpcValue;

  /// The `gamification.leaderboard.metrics.*` translation key.
  String get labelKey => 'gamification.leaderboard.metrics.$rpcValue';

  /// `true` when the metric is an amount rather than a count.
  bool get isCurrency => this == LeaderboardMetric.deductibleTotal;
}

/// The RPC hard-caps the number of rows it returns.
const int leaderboardMaxLimit = 100;

/// One row of the leaderboard RPC.
///
/// The SQL response carries no metric name, so the metric is attached by the
/// caller ([LeaderboardResult]).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.isCurrentUser = false,
    this.isAnonymous = false,
    this.metricValue = 0,
    this.gapToTopTen = 0,
  });

  final int rank;
  final String userId;
  final String displayName;
  final bool isCurrentUser;
  final bool isAnonymous;
  final double metricValue;

  /// Points/amount missing to enter the top ten; `0` when already inside it.
  final double gapToTopTen;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      rank: GamificationJson.asInt(GamificationJson.pick(map, 'rank')),
      userId: GamificationJson.stringOr(GamificationJson.pick(map, 'user_id')),
      displayName: GamificationJson.stringOr(
        GamificationJson.pick(map, 'display_name'),
      ),
      isCurrentUser: GamificationJson.asBool(
        GamificationJson.pick(map, 'is_current_user'),
      ),
      isAnonymous: GamificationJson.asBool(
        GamificationJson.pick(map, 'is_anonymous'),
      ),
      metricValue: GamificationJson.asDouble(
        GamificationJson.pick(map, 'metric_value'),
      ),
      gapToTopTen: GamificationJson.asDouble(
        GamificationJson.pick(map, 'gap_to_top_ten'),
      ),
    );
  }

  static List<LeaderboardEntry> parseRows(List<dynamic> rows) => rows
      .whereType<Map>()
      .map((row) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(row)))
      .toList();
}

/// A parsed leaderboard board.
///
/// [optedOut] marks the privacy gate: the board was never fetched because the
/// user has `leaderboard_opt_in = false`.
class LeaderboardResult {
  const LeaderboardResult({
    required this.metric,
    this.entries = const <LeaderboardEntry>[],
    this.optedOut = false,
  });

  const LeaderboardResult.optedOut(this.metric)
    : entries = const <LeaderboardEntry>[],
      optedOut = true;

  final LeaderboardMetric metric;
  final List<LeaderboardEntry> entries;
  final bool optedOut;

  bool get isEmpty => entries.isEmpty;

  /// The signed-in user's row.
  ///
  /// The RPC always includes that row, even when the user ranks below the
  /// returned limit, so it is found by scanning — never by index or by assuming
  /// it sits inside the first page of ranks.
  LeaderboardEntry? get currentUserEntry {
    for (final entry in entries) {
      if (entry.isCurrentUser) return entry;
    }
    return null;
  }

  /// Ranks 1-3 for the podium, ordered by rank so callers can render by index.
  List<LeaderboardEntry> get podium {
    final top =
        entries.where((entry) => entry.rank >= 1 && entry.rank <= 3).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));
    return top.take(3).toList();
  }

  /// Every rank outside the podium, in the order the server returned them.
  List<LeaderboardEntry> get remainingRanks =>
      entries.where((entry) => entry.rank > 3).toList();

  factory LeaderboardResult.fromRows({
    required LeaderboardMetric metric,
    required List<dynamic> rows,
  }) {
    return LeaderboardResult(
      metric: metric,
      entries: LeaderboardEntry.parseRows(rows),
    );
  }
}

/// One leaderboard query: a metric plus the board scope.
class LeaderboardQuery {
  const LeaderboardQuery({required this.metric, this.malaysiaOnly = true});

  final LeaderboardMetric metric;

  /// `true` for the Malaysian board, `false` for the global one.
  final bool malaysiaOnly;

  /// `_country_code` argument: `'MY'` for the Malaysian board, `null` (all
  /// countries) for the global board.
  String? get countryCode => malaysiaOnly ? 'MY' : null;

  @override
  bool operator ==(Object other) =>
      other is LeaderboardQuery &&
      other.metric == metric &&
      other.malaysiaOnly == malaysiaOnly;

  @override
  int get hashCode => Object.hash(metric, malaysiaOnly);
}
