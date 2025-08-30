import '../../../core/services/app_logger.dart';
import '../../../core/network/supabase_client.dart';
import '../services/team_invitation_service.dart';

/// Debug utility for team invitations functionality
class TeamInvitationDebugger {
  
  /// Run comprehensive debug checks for team invitations
  static Future<void> runDebugChecks(String teamId) async {
    AppLogger.debug('🔍 Team Invitations Debug Report for team: $teamId');
    
    try {
      // 1. Check user authentication
      await _checkAuthentication();
      
      // 2. Check team membership and role
      await _checkTeamMembership(teamId);
      
      // 3. Test database function
      await _testDatabaseFunction(teamId);
      
      // 4. Test direct table query
      await _testDirectTableQuery(teamId);
      
      // 5. Check for existing invitations
      await _checkExistingInvitations(teamId);
      
      // 6. Test service layer
      await _testServiceLayer(teamId);
      
    } catch (error) {
      AppLogger.error('💥 Debug checks failed', error);
    }
  }
  
  /// Check user authentication status
  static Future<void> _checkAuthentication() async {
    AppLogger.debug('1️⃣ Authentication Check');
    
    try {
      final user = SupabaseService.client.auth.currentUser;
      
      if (user == null) {
        AppLogger.error('❌ No authenticated user');
        return;
      }
      
      AppLogger.debug('✅ User authenticated: ${user.id} (${user.email})');
      
    } catch (error) {
      AppLogger.error('💥 Authentication check failed', error);
    }
  }
  
  /// Check team membership and role
  static Future<void> _checkTeamMembership(String teamId) async {
    AppLogger.debug('2️⃣ Team Membership Check');
    
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        AppLogger.error('❌ No authenticated user for membership check');
        return;
      }
      
      // Check team membership
      final membershipResponse = await SupabaseService.client
          .from('team_members')
          .select('*')
          .eq('team_id', teamId)
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (membershipResponse == null) {
        AppLogger.error('❌ User is not a member of this team');
        return;
      }
      
      final role = membershipResponse['role'] as String?;
      AppLogger.debug('✅ Team membership found: ${user.id} has role $role in team $teamId');
      
      // Check if role allows viewing invitations
      final canViewInvitations = ['owner', 'admin'].contains(role);
      AppLogger.debug('${canViewInvitations ? '✅' : '❌'} Can view invitations: $canViewInvitations');
      
    } catch (error) {
      AppLogger.error('💥 Team membership check failed', error);
    }
  }
  
  /// Test the database function
  static Future<void> _testDatabaseFunction(String teamId) async {
    AppLogger.debug('3️⃣ Database Function Test');
    
    try {
      final response = await SupabaseService.client.rpc(
        'get_team_invitations',
        params: {
          '_team_id': teamId,
          '_status': null,
          '_include_expired': true,
        },
      );
      
      AppLogger.debug('✅ Database function works: ${response?.length ?? 0} invitations returned');
      if (response != null && response.isNotEmpty) {
        AppLogger.debug('Sample invitation: ${response.first}');
      }
      
    } catch (error) {
      AppLogger.error('❌ Database function test failed', error);
    }
  }
  
  /// Test direct table query
  static Future<void> _testDirectTableQuery(String teamId) async {
    AppLogger.debug('4️⃣ Direct Table Query Test');
    
    try {
      final response = await SupabaseService.client
          .from('team_invitations')
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
            updated_at
          ''')
          .eq('team_id', teamId)
          .order('created_at', ascending: false);
      
      AppLogger.debug('✅ Direct table query works: ${response.length} invitations returned');
      if (response.isNotEmpty) {
        AppLogger.debug('Sample invitation: ${response.first}');
      }
      
    } catch (error) {
      AppLogger.error('❌ Direct table query test failed', error);
    }
  }
  
  /// Check for any existing invitations in the database
  static Future<void> _checkExistingInvitations(String teamId) async {
    AppLogger.debug('5️⃣ Existing Invitations Check');
    
    try {
      final response = await SupabaseService.client
          .from('team_invitations')
          .select('id, email, status, created_at')
          .eq('team_id', teamId);
      
      AppLogger.debug('📊 Invitation statistics: ${response.length} total invitations');
      
      if (response.isNotEmpty) {
        final statusCounts = <String, int>{};
        for (final invitation in response) {
          final status = invitation['status'] as String;
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        
        AppLogger.debug('📈 Status breakdown: $statusCounts');
      }
      
    } catch (error) {
      AppLogger.error('💥 Existing invitations check failed', error);
    }
  }
  
  /// Test service layer
  static Future<void> _testServiceLayer(String teamId) async {
    AppLogger.debug('6️⃣ Service Layer Test');
    
    try {
      final invitations = await TeamInvitationService.getTeamInvitations(
        teamId: teamId,
        includeExpired: true,
      );
      
      AppLogger.debug('✅ Service layer works: ${invitations.length} invitations loaded');
      
      final stats = await TeamInvitationService.getInvitationStats(teamId);
      AppLogger.debug('📊 Service stats: $stats');
      
    } catch (error) {
      AppLogger.error('❌ Service layer test failed', error);
    }
  }
  
  /// Quick debug function for easy access
  static Future<void> debugTeamInvitations(String teamId) async {
    return runDebugChecks(teamId);
  }
}
