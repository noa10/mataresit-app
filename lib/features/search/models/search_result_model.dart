import 'package:equatable/equatable.dart';

/// Wire-level source names accepted by the `unified-search` edge function.
///
/// The API uses **singular** names. Sending the plural UI names
/// (`receipts`, `custom_categories`) is rejected with HTTP 400.
class SearchSources {
  const SearchSources._();

  static const String receipt = 'receipt';
  static const String claim = 'claim';
  static const String teamMember = 'team_member';
  static const String customCategory = 'custom_category';
  static const String businessDirectory = 'business_directory';
  static const String conversation = 'conversation';

  /// Sources the free tier may query. The app cannot read the user's
  /// subscription tier here, so the UI only offers these.
  static const List<String> freeTier = [
    receipt,
    customCategory,
    businessDirectory,
  ];
}

/// A single search hit returned by `unified-search`.
class SearchResultItem extends Equatable {
  final String id;

  /// Raw `sourceType` from the server, kept as an open string on purpose: the
  /// server also emits `line_item`, `financial_analysis`, `error` and raw
  /// database `source_type` values that are outside the documented set.
  final String sourceType;
  final String sourceId;
  final String contentType;
  final String title;
  final String description;

  /// Vector similarity in the range 0..1.
  final double similarity;
  final Map<String, dynamic> metadata;
  final String? accessLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SearchResultItem({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    this.contentType = '',
    this.title = '',
    this.description = '',
    this.similarity = 0.0,
    this.metadata = const {},
    this.accessLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      id: _asString(json['id']),
      sourceType: _asString(json['sourceType'], fallback: 'unknown'),
      sourceId: _asString(json['sourceId']),
      contentType: _asString(json['contentType']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      similarity: _asDouble(json['similarity']),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      accessLevel: json['accessLevel'] is String
          ? json['accessLevel'] as String
          : null,
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  /// Similarity rendered as a whole percentage (0..100).
  int get similarityPercent => (similarity.clamp(0.0, 1.0) * 100).round();

  bool get isReceipt => sourceType == SearchSources.receipt;

  @override
  List<Object?> get props => [
    id,
    sourceType,
    sourceId,
    contentType,
    title,
    description,
    similarity,
    metadata,
    accessLevel,
    createdAt,
    updatedAt,
  ];
}

/// Pagination block of the search envelope.
class SearchPagination extends Equatable {
  /// Null when the server omitted the flag entirely.
  final bool? hasMore;

  /// Absent on the enhanced path — callers must derive the next offset from
  /// `offset + results.length` instead of trusting this field.
  final int? nextOffset;
  final int? totalPages;

  const SearchPagination({this.hasMore, this.nextOffset, this.totalPages});

  factory SearchPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SearchPagination();

    return SearchPagination(
      hasMore: json['hasMore'] is bool ? json['hasMore'] as bool : null,
      nextOffset: _asInt(json['nextOffset']),
      totalPages: _asInt(json['totalPages']),
    );
  }

  @override
  List<Object?> get props => [hasMore, nextOffset, totalPages];
}

/// Diagnostic block of the search envelope.
class SearchMetadata extends Equatable {
  final List<String> sourcesSearched;
  final int? searchDuration;
  final String? modelUsed;

  /// Non-empty when the server had to fall back to a degraded search path.
  final List<String> fallbacksUsed;

  const SearchMetadata({
    this.sourcesSearched = const [],
    this.searchDuration,
    this.modelUsed,
    this.fallbacksUsed = const [],
  });

  factory SearchMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SearchMetadata();

    return SearchMetadata(
      sourcesSearched: _asStringList(json['sourcesSearched']),
      searchDuration: _asInt(json['searchDuration']),
      modelUsed: json['modelUsed'] is String
          ? json['modelUsed'] as String
          : null,
      fallbacksUsed: _asStringList(json['fallbacksUsed']),
    );
  }

  /// `unified-search` answers HTTP 200 with `success: true` even when the RAG
  /// pipeline failed and the legacy search took over. The UI reads this to show
  /// a partial-results hint rather than pretending the results are complete.
  bool get isDegraded =>
      fallbacksUsed.isNotEmpty || modelUsed == 'fallback-search';

  @override
  List<Object?> get props => [
    sourcesSearched,
    searchDuration,
    modelUsed,
    fallbacksUsed,
  ];
}

/// Request body for `unified-search`.
///
/// The server rejects a query longer than 1000 characters, a limit outside 1..100
/// and a negative offset; this client sends values inside those bounds.
class SearchRequest extends Equatable {
  final String query;
  final List<String> sources;
  final int limit;
  final int offset;

  const SearchRequest({
    required this.query,
    this.sources = const [
      SearchSources.receipt,
      SearchSources.businessDirectory,
    ],
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'sources': sources,
    'limit': limit,
    'offset': offset,
  };

  @override
  List<Object?> get props => [query, sources, limit, offset];
}

/// Parsed `unified-search` response envelope.
class SearchResponse extends Equatable {
  final bool success;
  final List<SearchResultItem> results;
  final int totalResults;
  final SearchMetadata metadata;
  final SearchPagination pagination;

  /// Present on every error shape the function emits.
  final String? error;

  /// Validation detail list. The server sends either a list of strings or a
  /// single string here, so it is always normalised to a list.
  final List<String> details;

  /// The enhanced (RAG) path also returns an AI-written summary. Nothing in
  /// this app renders it — the AI chat surface is out of scope — but it is part
  /// of the documented envelope, so it is parsed rather than silently dropped.
  final String? enhancedContent;
  final List<String> followUpSuggestions;
  final double? confidence;
  final String? responseType;

  const SearchResponse({
    required this.success,
    this.results = const [],
    this.totalResults = 0,
    this.metadata = const SearchMetadata(),
    this.pagination = const SearchPagination(),
    this.error,
    this.details = const [],
    this.enhancedContent,
    this.followUpSuggestions = const [],
    this.confidence,
    this.responseType,
  });

  /// Parses both error body shapes the function emits: the bare
  /// `{success: false, error, details?}` body (no `results` key at all) and the
  /// full envelope with `results: []`.
  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final enhanced = _asMap(json['enhancedResponse']);

    return SearchResponse(
      success: json['success'] == true,
      results: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) => SearchResultItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      totalResults: _asInt(json['totalResults']) ?? 0,
      metadata: SearchMetadata.fromJson(_asMap(json['searchMetadata'])),
      pagination: SearchPagination.fromJson(_asMap(json['pagination'])),
      error: json['error'] is String ? json['error'] as String : null,
      details: _asStringList(json['details']),
      enhancedContent: enhanced?['content'] is String
          ? enhanced!['content'] as String
          : null,
      followUpSuggestions: _asStringList(enhanced?['followUpSuggestions']),
      confidence: _asDoubleOrNull(enhanced?['confidence']),
      responseType: enhanced?['responseType'] is String
          ? enhanced!['responseType'] as String
          : null,
    );
  }

  /// Authentication failures surface as HTTP 500 on the regular path and as
  /// HTTP 401 on the enhanced path, so the status code alone does not identify
  /// them — the server's wording does.
  static const List<String> _authErrorMarkers = [
    'Missing Authorization header',
    'Invalid authentication token',
  ];

  static bool looksLikeAuthFailure(String? error) {
    if (error == null) return false;
    return _authErrorMarkers.any(error.contains);
  }

  bool get isAuthFailure => looksLikeAuthFailure(error);

  @override
  List<Object?> get props => [
    success,
    results,
    totalResults,
    metadata,
    pagination,
    error,
    details,
    enhancedContent,
    followUpSuggestions,
    confidence,
    responseType,
  ];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

double _asDouble(dynamic value) => _asDoubleOrNull(value) ?? 0.0;

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.where((item) => item != null).map((item) => '$item').toList();
  }
  if (value is String && value.isNotEmpty) return [value];
  return const [];
}
