import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/teams/providers/teams_provider.dart';

class DatabaseDebugScreen extends ConsumerStatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  ConsumerState<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends ConsumerState<DatabaseDebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      final client = Supabase.instance.client;
      _addOutput('Testing database connection...');

      // Test basic connection
      _addOutput('Supabase client initialized: ${client.supabaseUrl}');
      _addOutput('Auth user: ${client.auth.currentUser?.id ?? 'Not authenticated'}');

      // Test current team
      final currentTeamState = ref.read(currentTeamProvider);
      _addOutput('Current team: ${currentTeamState.currentTeam?.id ?? 'None'} - ${currentTeamState.currentTeam?.name ?? 'None'}');

      if (currentTeamState.currentTeam != null) {
        final teamId = currentTeamState.currentTeam!.id;
        _addOutput('Testing with team ID: $teamId');

        // Test claims table existence
        try {
          final testResponse = await client
              .from('claims')
              .select('id')
              .limit(1);
          _addOutput('Claims table exists, test query returned: ${testResponse.runtimeType}');
          _addOutput('Test response: $testResponse');
        } catch (e) {
          _addOutput('Claims table test failed: $e');
        }

        // Test RPC function
        try {
          final rpcResponse = await client.rpc('get_team_claims', params: {
            '_team_id': teamId,
            '_status': null,
            '_limit': 5,
            '_offset': 0,
          });
          _addOutput('RPC get_team_claims exists, returned: ${rpcResponse.runtimeType}');
          _addOutput('RPC response: $rpcResponse');
        } catch (e) {
          _addOutput('RPC get_team_claims failed: $e');
        }

        // Test direct claims query
        try {
          final directResponse = await client
              .from('claims')
              .select('*')
              .eq('team_id', teamId)
              .limit(5);
          _addOutput('Direct claims query returned: ${directResponse.runtimeType}');
          _addOutput('Direct response length: ${directResponse is List ? directResponse.length : 'Not a list'}');
          if (directResponse is List && directResponse.isNotEmpty) {
            _addOutput('First claim: ${directResponse.first}');
          }
        } catch (e) {
          _addOutput('Direct claims query failed: $e');
        }

        // Test all claims without team filter
        try {
          final allClaimsResponse = await client
              .from('claims')
              .select('*')
              .limit(5);
          _addOutput('All claims query returned: ${allClaimsResponse.runtimeType}');
          _addOutput('All claims length: ${allClaimsResponse is List ? allClaimsResponse.length : 'Not a list'}');
          if (allClaimsResponse is List && allClaimsResponse.isNotEmpty) {
            _addOutput('First claim (any team): ${allClaimsResponse.first}');
          }
        } catch (e) {
          _addOutput('All claims query failed: $e');
        }
      }

    } catch (e) {
      _addOutput('Database test failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testDatabaseConnection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testDatabaseConnection,
              child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Database Connection'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'Tap "Test Database Connection" to start debugging...' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
