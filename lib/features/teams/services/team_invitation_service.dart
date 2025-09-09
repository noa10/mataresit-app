import '../../../core/services/app_logger.dart';
import '../../../shared/models/team_invitation_model.dart';
import '../../../shared/models/team_model.dart';
import '../../../core/network/supabase_client.dart';

/// Service for managing team invitations with Supabase integration
class TeamInvitationService {
  static const String _tableName = 'team_invitations';

  /// Get team invitations for a specific team
  static Future<List<TeamInvitationModel>> getTeamInvitations({
    required String teamId,
    InvitationStatus? status,
    bool includeExpired = true,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug('🔍 Loading team invitations for team: $teamId', {
        'status': status?.name,
        'includeExpired': includeExpired,
        'limit': limit,
        'offset': offset,
      });

      // First try using the database function (matches React implementation)
      try {
        AppLogger.debug('🔄 Trying database function get_team_invitations...');
        final functionResponse = await SupabaseService.client.rpc(
          'get_team_invitations',
          params: {
            '_team_id': teamId,
            '_status': status?.name,
            '_include_expired': includeExpired,
          },
        );

        if (functionResponse != null) {
          AppLogger.debug(
            '✅ Database function returned ${functionResponse.length} invitations',
            {
              'sample': functionResponse.isNotEmpty
                  ? functionResponse.first
                  : null,
            },
          );

          final invitations = (functionResponse as List)
              .map(
                (json) =>
                    TeamInvitationModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          // Apply client-side pagination if needed
          if (offset != null || limit != null) {
            final start = offset ?? 0;
            final end = start + (limit ?? 50);
            return invitations.sublist(
              start,
              end > invitations.length ? invitations.length : end,
            );
          }

          return invitations;
        }
      } catch (functionError) {
        AppLogger.warning(
          '🔄 Database function failed, falling back to direct query',
          functionError,
        );
      }

      // Fallback to direct table query
      var query = SupabaseService.client
          .from(_tableName)
          .select('''
            id,
            team_id,
            email,
            role,
            invited_by,
            status,
            token,
            expires_at,
            accepted_at,
            created_at,
            updated_at,
            invitation_attempts,
            last_sent_at,
            custom_message,
            permissions,
            metadata
          ''')
          .eq('team_id', teamId);

      // Apply status filter
      if (status != null) {
        query = query.eq('status', status.name);
      }

      // Apply expired filter
      if (!includeExpired) {
        query = query.gt('expires_at', DateTime.now().toIso8601String());
      }

      // Build the final query with ordering and pagination
      final finalQuery = query.order('created_at', ascending: false);

      // Apply pagination if needed
      final response = await (limit != null || offset != null
          ? finalQuery.range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1)
          : finalQuery);

      AppLogger.debug('✅ Direct query returned ${response.length} invitations');

      return (response as List)
          .map(
            (json) =>
                TeamInvitationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      AppLogger.error('💥 Failed to load team invitations', error);
      rethrow;
    }
  }

  /// Send a team invitation
  static Future<String> sendInvitation({
    required String teamId,
    required String email,
    required TeamRole role,
    String? customMessage,
    Map<String, dynamic>? permissions,
    int expiresInDays = 7,
    bool sendEmail = true,
  }) async {
    try {
      AppLogger.debug('📤 Sending team invitation', {
        'teamId': teamId,
        'email': email,
        'role': role.name,
      });

      final response = await SupabaseService.client.rpc(
        'invite_team_member_enhanced',
        params: {
          '_team_id': teamId,
          '_email': email,
          '_role': role.name,
          '_custom_message': customMessage,
          '_permissions': permissions ?? {},
          '_expires_in_days': expiresInDays,
          '_send_email': sendEmail,
        },
      );

      if (response is Map<String, dynamic>) {
        if (response['success'] == true) {
          AppLogger.debug('✅ Invitation sent successfully');
          return response['invitation_id'] as String;
        } else {
          throw Exception(response['error'] ?? 'Failed to send invitation');
        }
      }

      throw Exception('Unexpected response format');
    } catch (error) {
      AppLogger.error('💥 Failed to send invitation', error);
      rethrow;
    }
  }

  /// Resend a team invitation
  static Future<void> resendInvitation({
    required String invitationId,
    String? customMessage,
    bool extendExpiration = true,
    int newExpirationDays = 7,
  }) async {
    try {
      AppLogger.debug('🔄 Resending invitation: $invitationId');

      final response = await SupabaseService.client.rpc(
        'resend_team_invitation',
        params: {
          '_invitation_id': invitationId,
          '_custom_message': customMessage,
          '_extend_expiration': extendExpiration,
          '_new_expiration_days': newExpirationDays,
        },
      );

      if (response is Map<String, dynamic> && response['success'] != true) {
        throw Exception(response['error'] ?? 'Failed to resend invitation');
      }

      AppLogger.debug('✅ Invitation resent successfully');
    } catch (error) {
      AppLogger.error('💥 Failed to resend invitation', error);
      rethrow;
    }
  }

  /// Cancel a team invitation
  static Future<void> cancelInvitation({
    required String invitationId,
    String? reason,
  }) async {
    try {
      AppLogger.debug('❌ Cancelling invitation: $invitationId');

      final response = await SupabaseService.client.rpc(
        'cancel_team_invitation',
        params: {
          '_invitation_id': invitationId,
          '_cancellation_reason': reason,
        },
      );

      if (response is Map<String, dynamic> && response['success'] != true) {
        throw Exception(response['error'] ?? 'Failed to cancel invitation');
      }

      AppLogger.debug('✅ Invitation cancelled successfully');
    } catch (error) {
      AppLogger.error('💥 Failed to cancel invitation', error);
      rethrow;
    }
  }

  /// Get invitation statistics for a team
  static Future<Map<String, int>> getInvitationStats(String teamId) async {
    try {
      final invitations = await getTeamInvitations(teamId: teamId);

      final stats = <String, int>{
        'total': invitations.length,
        'pending': 0,
        'accepted': 0,
        'expired': 0,
        'cancelled': 0,
      };

      for (final invitation in invitations) {
        switch (invitation.status) {
          case InvitationStatus.pending:
            if (invitation.isExpired) {
              stats['expired'] = (stats['expired'] ?? 0) + 1;
            } else {
              stats['pending'] = (stats['pending'] ?? 0) + 1;
            }
            break;
          case InvitationStatus.accepted:
            stats['accepted'] = (stats['accepted'] ?? 0) + 1;
            break;
          case InvitationStatus.expired:
            stats['expired'] = (stats['expired'] ?? 0) + 1;
            break;
          case InvitationStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (error) {
      AppLogger.error('💥 Failed to get invitation stats', error);
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'expired': 0,
        'cancelled': 0,
      };
    }
  }
}
