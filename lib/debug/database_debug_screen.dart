import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../features/teams/providers/teams_provider.dart';
import '../core/services/ai_vision_service_manager.dart';
import '../core/services/processing_logs_service.dart';
import '../core/constants/app_constants.dart';

class DatabaseDebugScreen extends ConsumerStatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  ConsumerState<DatabaseDebugScreen> createState() =>
      _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends ConsumerState<DatabaseDebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  Future<void> _testGeminiService() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addOutput('Testing Gemini Vision Service...');

      // Check environment variables
      _addOutput('\n=== Environment Check ===');
      _addOutput(
        'Raw .env GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.isNotEmpty == true ? 'SET' : 'NOT SET'}',
      );
      _addOutput(
        'AppConstants.geminiApiKey: ${AppConstants.geminiApiKey.isNotEmpty ? 'SET (${AppConstants.geminiApiKey.substring(0, 10)}...)' : 'NOT SET'}',
      );

      // Check service status
      final status = AIVisionServiceManager.getServicesStatus();
      _addOutput('\n=== AI Vision Services Status ===');
      _addOutput('Services Status: $status');

      if (!AIVisionServiceManager.hasConfiguredServices()) {
        _addOutput('❌ No AI vision services are configured');
        _addOutput(
          'Please ensure GEMINI_API_KEY or OPENROUTER_API_KEY is set in .env file',
        );
        return;
      }

      _addOutput('✅ Gemini service is configured');

      // Test basic connection
      try {
        _addOutput('\n=== Connection Test ===');
        _addOutput('Testing all configured services...');
        final testResults = await AIVisionServiceManager.testAllConnections();
        for (final entry in testResults.entries) {
          if (entry.value.startsWith('OK:')) {
            _addOutput('✅ ${entry.key}: ${entry.value}');
          } else {
            _addOutput('❌ ${entry.key}: ${entry.value}');
          }
        }
      } catch (e) {
        _addOutput('❌ Connection test failed: $e');
      }
    } catch (e) {
      _addOutput('Gemini test failed: $e');
    }

    setState(() {
      _isLoading = false;
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
      _addOutput('Supabase client initialized');
      _addOutput(
        'Auth user: ${client.auth.currentUser?.id ?? 'Not authenticated'}',
      );

      // Test current team
      final currentTeamState = ref.read(currentTeamProvider);
      _addOutput(
        'Current team: ${currentTeamState.currentTeam?.id ?? 'None'} - ${currentTeamState.currentTeam?.name ?? 'None'}',
      );

      if (currentTeamState.currentTeam != null) {
        final teamId = currentTeamState.currentTeam!.id;
        _addOutput('Testing with team ID: $teamId');

        // Test claims table existence
        try {
          final testResponse = await client
              .from('claims')
              .select('id')
              .limit(1);
          _addOutput(
            'Claims table exists, test query returned: ${testResponse.runtimeType}',
          );
          _addOutput('Test response: $testResponse');
        } catch (e) {
          _addOutput('Claims table test failed: $e');
        }

        // Test RPC function
        try {
          final rpcResponse = await client.rpc(
            'get_team_claims',
            params: {
              '_team_id': teamId,
              '_status': null,
              '_limit': 5,
              '_offset': 0,
            },
          );
          _addOutput('RPC response: $rpcResponse');
          _addOutput('RPC response length: ${rpcResponse.length}');
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
          _addOutput(
            'Direct claims query returned: ${directResponse.runtimeType}',
          );
          _addOutput('Direct response length: ${directResponse.length}');
          if (directResponse.isNotEmpty) {
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
          _addOutput(
            'All claims query returned: ${allClaimsResponse.runtimeType}',
          );
          _addOutput('All claims length: ${allClaimsResponse.length}');
          if (allClaimsResponse.isNotEmpty) {
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

  Future<void> _testProcessingLogsAuth() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addOutput('Testing Processing Logs Authentication...');

      // Test authentication state
      final logsService = ProcessingLogsService();
      final authResult = await logsService.testAuthAndRLS();

      _addOutput('\n=== Authentication State ===');
      _addOutput('Has User: ${authResult['hasUser']}');
      _addOutput('User ID: ${authResult['userId'] ?? 'null'}');
      _addOutput('User Email: ${authResult['userEmail'] ?? 'null'}');
      _addOutput('Has Session: ${authResult['hasSession']}');
      _addOutput('Session Valid: ${authResult['sessionValid']}');
      _addOutput('Session Expiry: ${authResult['sessionExpiry'] ?? 'null'}');

      if (authResult['canQueryReceipts'] == true) {
        _addOutput('✅ Can query receipts (${authResult['receiptsCount']} found)');
      } else {
        _addOutput('❌ Cannot query receipts: ${authResult['receiptsError']}');
      }

      // Test processing logs insertion
      if (authResult['hasUser'] == true && authResult['sessionValid'] == true) {
        _addOutput('\n=== Testing Processing Logs Insert ===');
        try {
          // Create a test receipt ID (this should fail if receipt doesn't exist)
          final testReceiptId = 'test-receipt-${DateTime.now().millisecondsSinceEpoch}';
          await logsService.saveProcessingLog(
            testReceiptId,
            'TEST',
            'Testing processing logs authentication',
          );
          _addOutput('✅ Processing log insert succeeded (unexpected - receipt should not exist)');
        } catch (e) {
          if (e.toString().contains('violates foreign key constraint') ||
              e.toString().contains('receipt_id')) {
            _addOutput('✅ Processing log insert failed as expected (receipt doesn\'t exist)');
            _addOutput('   This means authentication is working, but receipt validation is also working');
          } else if (e.toString().contains('row-level security policy')) {
            _addOutput('❌ RLS policy still blocking insert: $e');
          } else {
            _addOutput('❓ Unexpected error: $e');
          }
        }
      } else {
        _addOutput('\n❌ Cannot test processing logs - user not authenticated');
        _addOutput('   Please sign in to test processing logs functionality');
      }

    } catch (e) {
      _addOutput('Processing logs test failed: $e');
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
              onPressed: _isLoading ? null : _testGeminiService,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Gemini Vision Service'),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testProcessingLogsAuth,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Processing Logs Auth'),
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
                    _debugOutput.isEmpty
                        ? 'Tap "Test Database Connection" to start debugging...'
                        : _debugOutput,
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
