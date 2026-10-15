import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../models/search_result_model.dart';

/// Failure raised by [SearchService] for both transport errors and the
/// server's own `success: false` envelopes.
class SearchException implements Exception {
  final String message;
  final List<String> details;

  /// True when the server rejected the request's credentials. Auth failures
  /// arrive as HTTP 500 on the regular path and 401 on the enhanced path, so
  /// this is derived from the status *and* the server's wording.
  final bool isAuthError;

  const SearchException(
    this.message, {
    this.details = const [],
    this.isAuthError = false,
  });

  @override
  String toString() => message;
}

/// Client for the `unified-search` edge function.
class SearchService {
  static final Logger _logger = Logger();
  static const String _functionName = 'unified-search';

  /// Uses the shared Supabase client so the user's JWT is attached
  /// automatically, matching the app's other edge function calls.
  SupabaseClient get _client => SupabaseService.client;

  /// Run a unified search. Throws [SearchException] on any failure.
  Future<SearchResponse> search(SearchRequest request) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: request.toJson(),
      );

      final body = _decodeBody(response.data);
      if (body == null) {
        throw const SearchException(
          'Search returned an unexpected response format.',
        );
      }

      final parsed = SearchResponse.fromJson(body);
      if (!parsed.success) {
        throw SearchException(
          parsed.error ?? 'Search failed.',
          details: parsed.details,
          isAuthError: parsed.isAuthFailure,
        );
      }

      if (parsed.metadata.isDegraded) {
        _logger.w(
          '⚠️ Search answered with degraded results '
          '(modelUsed: ${parsed.metadata.modelUsed}, '
          'fallbacksUsed: ${parsed.metadata.fallbacksUsed})',
        );
      }

      return parsed;
    } on SearchException {
      rethrow;
    } on FunctionException catch (e) {
      throw _fromFunctionException(e);
    } catch (e) {
      _logger.e('❌ Unified search failed: $e');
      throw SearchException('Search failed: $e');
    }
  }

  /// `functions.invoke` throws on non-2xx responses and carries the decoded
  /// body in `details`, which may be a bare error map or the full envelope.
  SearchException _fromFunctionException(FunctionException e) {
    final body = _decodeBody(e.details);
    final parsed = body == null ? null : SearchResponse.fromJson(body);
    final serverError = parsed?.error;
    final message =
        serverError ?? e.reasonPhrase ?? 'Search failed (HTTP ${e.status}).';
    final isAuthError =
        e.status == 401 || SearchResponse.looksLikeAuthFailure(serverError);

    _logger.w('⚠️ Search HTTP ${e.status}: $message');

    return SearchException(
      message,
      details: parsed?.details ?? const [],
      isAuthError: isAuthError,
    );
  }

  Map<String, dynamic>? _decodeBody(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        _logger.d('Search response was not JSON: $e');
      }
    }

    return null;
  }
}

/// Provider for the unified search service.
final searchServiceProvider = Provider<SearchService>((ref) => SearchService());
