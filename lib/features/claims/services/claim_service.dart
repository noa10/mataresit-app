import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../shared/models/claim_model.dart';
import '../../../shared/models/claim_requests.dart';

/// Service for managing claims with Supabase integration
class ClaimService {
  final SupabaseClient _client;

  ClaimService(this._client);

  // =============================================
  // CLAIM MANAGEMENT
  // =============================================

  /// Create a new claim
  Future<String> createClaim(CreateClaimRequest request) async {
    try {
      final response = await _client.rpc('create_claim', params: {
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
      });

      if (response == null) {
        throw Exception('Failed to create claim');
      }

      return response as String;
    } catch (e) {
      throw Exception('Failed to create claim: $e');
    }
  }

  /// Get claim by ID
  Future<ClaimModel?> getClaimById(String claimId) async {
    try {
      final response = await _client
          .from('claims')
          .select('''
            *,
            claimant:profiles!claimant_id(first_name, last_name, email),
            reviewer:profiles!reviewed_by(first_name, last_name, email),
            approver:profiles!approved_by(first_name, last_name, email)
          ''')
          .eq('id', claimId)
          .maybeSingle();

      if (response == null) return null;

      // Transform joined data
      final transformedData = Map<String, dynamic>.from(response);
      if (response['claimant'] != null) {
        final claimant = response['claimant'] as Map<String, dynamic>;
        transformedData['claimant_name'] = 
            '${claimant['first_name']} ${claimant['last_name']}'.trim();
        transformedData['claimant_email'] = claimant['email'];
      }
      if (response['reviewer'] != null) {
        final reviewer = response['reviewer'] as Map<String, dynamic>;
        transformedData['reviewer_name'] = 
            '${reviewer['first_name']} ${reviewer['last_name']}'.trim();
      }
      if (response['approver'] != null) {
        final approver = response['approver'] as Map<String, dynamic>;
        transformedData['approver_name'] = 
            '${approver['first_name']} ${approver['last_name']}'.trim();
      }

      // Remove the joined objects to avoid conflicts
      transformedData.remove('claimant');
      transformedData.remove('reviewer');
      transformedData.remove('approver');

      return ClaimModel.fromJson(transformedData);
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
      var query = _client
          .from('claims')
          .select('''
            *,
            claimant:profiles!claimant_id(first_name, last_name, email),
            reviewer:profiles!reviewed_by(first_name, last_name, email),
            approver:profiles!approved_by(first_name, last_name, email)
          ''')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);

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

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;

      return response.map<ClaimModel>((data) {
        // Transform joined data
        final transformedData = Map<String, dynamic>.from(data);
        if (data['claimant'] != null) {
          final claimant = data['claimant'] as Map<String, dynamic>;
          transformedData['claimant_name'] = 
              '${claimant['first_name']} ${claimant['last_name']}'.trim();
          transformedData['claimant_email'] = claimant['email'];
        }
        if (data['reviewer'] != null) {
          final reviewer = data['reviewer'] as Map<String, dynamic>;
          transformedData['reviewer_name'] = 
              '${reviewer['first_name']} ${reviewer['last_name']}'.trim();
        }
        if (data['approver'] != null) {
          final approver = data['approver'] as Map<String, dynamic>;
          transformedData['approver_name'] = 
              '${approver['first_name']} ${approver['last_name']}'.trim();
        }

        // Remove the joined objects to avoid conflicts
        transformedData.remove('claimant');
        transformedData.remove('reviewer');
        transformedData.remove('approver');

        return ClaimModel.fromJson(transformedData);
      }).toList();
    } catch (e) {
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
      var query = _client
          .from('claims')
          .select('''
            *,
            claimant:profiles!claimant_id(first_name, last_name, email),
            reviewer:profiles!reviewed_by(first_name, last_name, email),
            approver:profiles!approved_by(first_name, last_name, email)
          ''')
          .eq('claimant_id', userId)
          .order('created_at', ascending: false);

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

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;

      return response.map<ClaimModel>((data) {
        // Transform joined data (same as getTeamClaims)
        final transformedData = Map<String, dynamic>.from(data);
        if (data['claimant'] != null) {
          final claimant = data['claimant'] as Map<String, dynamic>;
          transformedData['claimant_name'] = 
              '${claimant['first_name']} ${claimant['last_name']}'.trim();
          transformedData['claimant_email'] = claimant['email'];
        }
        if (data['reviewer'] != null) {
          final reviewer = data['reviewer'] as Map<String, dynamic>;
          transformedData['reviewer_name'] = 
              '${reviewer['first_name']} ${reviewer['last_name']}'.trim();
        }
        if (data['approver'] != null) {
          final approver = data['approver'] as Map<String, dynamic>;
          transformedData['approver_name'] = 
              '${approver['first_name']} ${approver['last_name']}'.trim();
        }

        transformedData.remove('claimant');
        transformedData.remove('reviewer');
        transformedData.remove('approver');

        return ClaimModel.fromJson(transformedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user claims: $e');
    }
  }

  /// Update claim
  Future<void> updateClaim(String claimId, UpdateClaimRequest request) async {
    try {
      final updateData = request.toUpdateMap();
      
      final response = await _client
          .from('claims')
          .update(updateData)
          .eq('id', claimId);

      // Supabase update doesn't throw on no rows affected, so we don't need to check
    } catch (e) {
      throw Exception('Failed to update claim: $e');
    }
  }

  /// Submit claim for review
  Future<void> submitClaim(String claimId) async {
    try {
      final response = await _client.rpc('submit_claim', params: {
        '_claim_id': claimId,
      });
    } catch (e) {
      throw Exception('Failed to submit claim: $e');
    }
  }

  /// Approve claim
  Future<void> approveClaim(ClaimApprovalRequest request) async {
    try {
      final response = await _client.rpc('approve_claim', params: {
        '_claim_id': request.claimId,
        '_comment': request.comment,
      });
    } catch (e) {
      throw Exception('Failed to approve claim: $e');
    }
  }

  /// Reject claim
  Future<void> rejectClaim(ClaimRejectionRequest request) async {
    try {
      final response = await _client.rpc('reject_claim', params: {
        '_claim_id': request.claimId,
        '_rejection_reason': request.rejectionReason,
      });
    } catch (e) {
      throw Exception('Failed to reject claim: $e');
    }
  }

  /// Delete claim (only if in draft status)
  Future<void> deleteClaim(String claimId) async {
    try {
      await _client
          .from('claims')
          .delete()
          .eq('id', claimId);
    } catch (e) {
      throw Exception('Failed to delete claim: $e');
    }
  }
}

/// Provider for claim service
final claimServiceProvider = Provider<ClaimService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClaimService(client);
});
