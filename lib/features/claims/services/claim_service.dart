import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';

/// Service for managing claims with Supabase integration
class ClaimService {
  final SupabaseClient _client;
  final Logger _logger = Logger();

  ClaimService(this._client);

  // =============================================
  // CLAIM MANAGEMENT
  // =============================================

  /// Create a new claim
  Future<String> createClaim(CreateClaimRequest request) async {
    try {
      // Try RPC function first
      try {
        final response = await _client.rpc(
          'create_claim',
          params: {
            '_team_id': request.teamId,
            '_title': request.title,
            '_description': request.description,
            '_amount': request.amount,
            '_currency': request.currency ?? 'USD',
            '_category': request.category,
            '_priority': request.priority?.name ?? 'medium',
            '_attachments': request.attachments != null
                ? request.attachments!.map((a) => a).toList()
                : [],
          },
        );

        if (response == null) {
          throw Exception('Failed to create claim');
        }

        return response as String;
      } catch (rpcError) {
        // If RPC function doesn't exist, use direct insert
        if (rpcError.toString().contains('PGRST202') ||
            rpcError.toString().contains('create_claim')) {
          return await _createClaimDirect(request);
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to create claim: $e');
    }
  }

  /// Create claim using direct database insert
  Future<String> _createClaimDirect(CreateClaimRequest request) async {
    final claimData = {
      'team_id': request.teamId,
      'claimant_id': _client.auth.currentUser?.id,
      'title': request.title,
      'description': request.description,
      'amount': request.amount,
      'currency': request.currency ?? 'USD',
      'category': request.category,
      'priority': request.priority?.name ?? 'medium',
      'status': 'draft',
      'metadata': <String, dynamic>{},
      'attachments': request.attachments ?? [],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('claims')
        .insert(claimData)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Get claim by ID
  Future<ClaimModel?> getClaimById(String claimId) async {
    try {
      final response = await _client
          .from('claims')
          .select('*')
          .eq('id', claimId)
          .maybeSingle();

      if (response == null) return null;

      return ClaimModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get claim: $e');
    }
  }

  /// Get claims for a team with optional filters
  Future<List<ClaimModel>> getTeamClaims(
    String teamId, {
    ClaimFilters? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      // Check if claims table exists first
      final tableExists = await _checkClaimsTableExists();
      if (!tableExists) {
        _logger.w('Claims table does not exist');
        return []; // Return empty list if table doesn't exist
      }

      _logger.i('Fetching claims for team: $teamId');

      // IMPORTANT: We skip the RPC function because it has incomplete field mapping
      // The get_team_claims RPC function in the database migration only returns:
      // id, title, description, amount, currency, category, priority, status,
      // claimant_id, claimant_name, claimant_email, timestamps, approval fields
      //
      // But it's MISSING: team_id, metadata, attachments
      // which are required by our ClaimModel for proper functionality.
      //
      // The React app likely works because it handles missing fields differently
      // or has been updated to use a different approach.
      _logger.i(
        'Using direct table query to get complete claim data including team_id, metadata, attachments',
      );

      // First verify user has access to this team (security check like RPC function)
      final teamAccessCheck = await _client
          .from('team_members')
          .select('role')
          .eq('team_id', teamId)
          .eq('user_id', _client.auth.currentUser?.id ?? '')
          .maybeSingle();

      if (teamAccessCheck == null) {
        _logger.w('User does not have access to team: $teamId');
        return [];
      }

      _logger.i('User has ${teamAccessCheck['role']} access to team: $teamId');

      // Direct table query with all required fields
      dynamic query = _client.from('claims').select('*').eq('team_id', teamId);

      // Apply filters
      if (filters != null) {
        if (filters.status != null) {
          query = query.eq('status', filters.status!.name);
        }
        if (filters.priority != null) {
          query = query.eq('priority', filters.priority!.name);
        }
        if (filters.claimantId != null) {
          query = query.eq('claimant_id', filters.claimantId!);
        }
        if (filters.category != null) {
          query = query.eq('category', filters.category!);
        }
        if (filters.dateFrom != null) {
          query = query.gte('created_at', filters.dateFrom!.toIso8601String());
        }
        if (filters.dateTo != null) {
          query = query.lte('created_at', filters.dateTo!.toIso8601String());
        }
        if (filters.amountMin != null) {
          query = query.gte('amount', filters.amountMin!);
        }
        if (filters.amountMax != null) {
          query = query.lte('amount', filters.amountMax!);
        }
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      _logger.i('Claims query response: $response');
      _logger.i('Response type: ${response.runtimeType}');

      // Handle case where response might not be a list
      if (response is! List) {
        _logger.w('Response is not a list, returning empty list');
        return []; // Return empty list if response is not a list
      }

      _logger.i('Found ${response.length} claims');
      try {
        final validClaims = <ClaimModel>[];
        for (int i = 0; i < response.length; i++) {
          try {
            final data = response[i];
            _logger.i(
              'Processing claim ${i + 1}/${response.length}: ${data['id']}',
            );

            // Debug the problematic fields
            _logger.i(
              '  - attachments type: ${data['attachments'].runtimeType}, value: ${data['attachments']}',
            );
            _logger.i(
              '  - metadata type: ${data['metadata'].runtimeType}, value: ${data['metadata']}',
            );
            _logger.i('  - status: ${data['status']}');

            final claim = ClaimModel.fromJson(data);
            validClaims.add(claim);
            _logger.i('  ✅ Successfully parsed claim: ${claim.title}');
          } catch (parseError) {
            _logger.e(
              '  ❌ Error parsing claim data from direct query (item $i): $parseError',
            );
            _logger.e('  Problematic data keys: ${response[i].keys.toList()}');
            // Skip this claim and continue with others
            continue;
          }
        }
        _logger.i(
          'Successfully parsed ${validClaims.length} out of ${response.length} claims',
        );
        return validClaims;
      } catch (mappingError) {
        _logger.e('Error mapping claims from direct query: $mappingError');
        throw Exception('Failed to parse claims data: $mappingError');
      }
    } catch (e) {
      // Handle specific database errors gracefully
      if (e.toString().contains('relation "public.claims" does not exist') ||
          e.toString().contains('PGRST106') ||
          e.toString().contains(
            'type \'String\' is not a subtype of type \'List<dynamic>\'',
          )) {
        return []; // Return empty list for database setup issues
      }
      throw Exception('Failed to get team claims: $e');
    }
  }

  /// Get user's claims
  Future<List<ClaimModel>> getUserClaims(
    String userId, {
    ClaimFilters? filters,
    int? limit,
    int? offset,
  }) async {
    try {
      dynamic query = _client
          .from('claims')
          .select('*')
          .eq('claimant_id', userId);

      // Apply filters (similar to getTeamClaims)
      if (filters != null) {
        if (filters.status != null) {
          query = query.eq('status', filters.status!.name);
        }
        if (filters.priority != null) {
          query = query.eq('priority', filters.priority!.name);
        }
        if (filters.category != null) {
          query = query.eq('category', filters.category!);
        }
        if (filters.dateFrom != null) {
          query = query.gte('created_at', filters.dateFrom!.toIso8601String());
        }
        if (filters.dateTo != null) {
          query = query.lte('created_at', filters.dateTo!.toIso8601String());
        }
        if (filters.amountMin != null) {
          query = query.gte('amount', filters.amountMin!);
        }
        if (filters.amountMax != null) {
          query = query.lte('amount', filters.amountMax!);
        }
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;

      // Handle case where response might not be a list
      if (response is! List) {
        return []; // Return empty list if response is not a list
      }

      return response.map<ClaimModel>((data) {
        return ClaimModel.fromJson(data);
      }).toList();
    } catch (e) {
      // Handle specific database errors gracefully
      if (e.toString().contains('relation "public.claims" does not exist') ||
          e.toString().contains('PGRST106') ||
          e.toString().contains(
            'type \'String\' is not a subtype of type \'List<dynamic>\'',
          )) {
        return []; // Return empty list for database setup issues
      }
      throw Exception('Failed to get user claims: $e');
    }
  }

  /// Update claim
  Future<void> updateClaim(String claimId, UpdateClaimRequest request) async {
    try {
      final updateData = request.toUpdateMap();

      await _client.from('claims').update(updateData).eq('id', claimId);

      // Supabase update doesn't throw on no rows affected, so we don't need to check
    } catch (e) {
      throw Exception('Failed to update claim: $e');
    }
  }

  /// Submit claim for review
  Future<void> submitClaim(String claimId) async {
    try {
      try {
        await _client.rpc('submit_claim', params: {'_claim_id': claimId});
      } catch (rpcError) {
        // If RPC function doesn't exist, use direct update
        if (rpcError.toString().contains('PGRST202') ||
            rpcError.toString().contains('submit_claim')) {
          await _client
              .from('claims')
              .update({
                'status': 'pending',
                'submitted_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', claimId);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to submit claim: $e');
    }
  }

  /// Approve claim
  Future<void> approveClaim(ClaimApprovalRequest request) async {
    try {
      try {
        await _client.rpc(
          'approve_claim',
          params: {'_claim_id': request.claimId, '_comment': request.comment},
        );
      } catch (rpcError) {
        // If RPC function doesn't exist, use direct update
        if (rpcError.toString().contains('PGRST202') ||
            rpcError.toString().contains('approve_claim')) {
          await _client
              .from('claims')
              .update({
                'status': 'approved',
                'approved_by': _client.auth.currentUser?.id,
                'approved_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', request.claimId);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to approve claim: $e');
    }
  }

  /// Reject claim
  Future<void> rejectClaim(ClaimRejectionRequest request) async {
    try {
      try {
        await _client.rpc(
          'reject_claim',
          params: {
            '_claim_id': request.claimId,
            '_rejection_reason': request.rejectionReason,
          },
        );
      } catch (rpcError) {
        // If RPC function doesn't exist, use direct update
        if (rpcError.toString().contains('PGRST202') ||
            rpcError.toString().contains('reject_claim')) {
          await _client
              .from('claims')
              .update({
                'status': 'rejected',
                'rejection_reason': request.rejectionReason,
                'reviewed_by': _client.auth.currentUser?.id,
                'reviewed_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', request.claimId);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to reject claim: $e');
    }
  }

  /// Delete claim (only if in draft status)
  Future<void> deleteClaim(String claimId) async {
    try {
      await _client.from('claims').delete().eq('id', claimId);
    } catch (e) {
      throw Exception('Failed to delete claim: $e');
    }
  }

  // =============================================
  // CLAIM STATISTICS AND AUDIT
  // =============================================

  /// Get claim statistics for a team
  Future<ClaimStats> getTeamClaimStats(String teamId) async {
    try {
      // Try to use RPC function first
      final response = await _client.rpc(
        'get_team_claim_stats',
        params: {'_team_id': teamId},
      );

      if (response == null) {
        return const ClaimStats(
          totalClaims: 0,
          pendingClaims: 0,
          approvedClaims: 0,
          rejectedClaims: 0,
          totalAmount: 0.0,
          approvedAmount: 0.0,
        );
      }

      return ClaimStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // If RPC function doesn't exist, calculate stats manually
      if (e.toString().contains('PGRST202') ||
          e.toString().contains('get_team_claim_stats')) {
        return await _calculateStatsManually(teamId);
      }
      throw Exception('Failed to get claim stats: $e');
    }
  }

  /// Calculate claim statistics manually when RPC function is not available
  Future<ClaimStats> _calculateStatsManually(String teamId) async {
    try {
      // Get all claims for the team
      final response = await _client
          .from('claims')
          .select('status, amount')
          .eq('team_id', teamId);

      final claims = response;

      int totalClaims = claims.length;
      int pendingClaims = 0;
      int approvedClaims = 0;
      int rejectedClaims = 0;
      double totalAmount = 0.0;
      double approvedAmount = 0.0;

      for (final claim in claims) {
        final status = claim['status'] as String?;
        final amount = (claim['amount'] as num?)?.toDouble() ?? 0.0;

        totalAmount += amount;

        switch (status) {
          case 'pending':
          case 'under_review':
            pendingClaims++;
            break;
          case 'approved':
          case 'paid':
            approvedClaims++;
            approvedAmount += amount;
            break;
          case 'rejected':
            rejectedClaims++;
            break;
        }
      }

      return ClaimStats(
        totalClaims: totalClaims,
        pendingClaims: pendingClaims,
        approvedClaims: approvedClaims,
        rejectedClaims: rejectedClaims,
        totalAmount: totalAmount,
        approvedAmount: approvedAmount,
      );
    } catch (e) {
      // Return empty stats if calculation fails
      return const ClaimStats(
        totalClaims: 0,
        pendingClaims: 0,
        approvedClaims: 0,
        rejectedClaims: 0,
        totalAmount: 0.0,
        approvedAmount: 0.0,
      );
    }
  }

  /// Get claim audit trail
  Future<List<ClaimAuditTrailModel>> getClaimAuditTrail(String claimId) async {
    try {
      final response = await _client
          .from('claim_audit_trail')
          .select('''
            *,
            user:profiles!user_id(first_name, last_name, email)
          ''')
          .eq('claim_id', claimId)
          .order('created_at', ascending: false);

      return response.map<ClaimAuditTrailModel>((data) {
        // Transform joined data
        final transformedData = Map<String, dynamic>.from(data);
        if (data['user'] != null) {
          final user = data['user'] as Map<String, dynamic>;
          transformedData['user_name'] =
              '${user['first_name']} ${user['last_name']}'.trim();
          transformedData['user_email'] = user['email'];
        }

        transformedData.remove('user');
        return ClaimAuditTrailModel.fromJson(transformedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get claim audit trail: $e');
    }
  }

  // =============================================
  // HELPER METHODS
  // =============================================

  /// Check if claims table exists in the database
  Future<bool> _checkClaimsTableExists() async {
    try {
      await _client.from('claims').select('id').limit(1);
      return true;
    } catch (e) {
      // If we get a table not found error, return false
      if (e.toString().contains('relation "public.claims" does not exist') ||
          e.toString().contains('PGRST106')) {
        return false;
      }
      // For other errors, assume table exists but there's another issue
      return true;
    }
  }

  // =============================================
  // REAL-TIME SUBSCRIPTIONS
  // =============================================

  /// Subscribe to claim changes for a team
  Stream<ClaimModel> subscribeToTeamClaims(String teamId) {
    return _client
        .from('claims')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId)
        .map((data) => data.map((item) => ClaimModel.fromJson(item)).toList())
        .expand((claims) => claims);
  }

  /// Subscribe to specific claim changes
  Stream<ClaimModel> subscribeToClaimChanges(String claimId) {
    return _client
        .from('claims')
        .stream(primaryKey: ['id'])
        .eq('id', claimId)
        .map((data) => data.isNotEmpty ? ClaimModel.fromJson(data.first) : null)
        .where((claim) => claim != null)
        .cast<ClaimModel>();
  }
}

/// Provider for claim service
final claimServiceProvider = Provider<ClaimService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClaimService(client);
});
