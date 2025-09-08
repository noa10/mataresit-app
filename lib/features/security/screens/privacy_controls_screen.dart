import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for privacy controls and data management
class PrivacyControlsScreen extends ConsumerWidget {
  const PrivacyControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Controls'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Data Export Section
          _buildSectionHeader('Data Export'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data as JSON'),
                  subtitle: const Text('Download all your data in JSON format'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showExportDialog(context, 'JSON');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Export Data as CSV'),
                  subtitle: const Text('Download receipts data in CSV format'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showExportDialog(context, 'CSV');
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Privacy Settings Section
          _buildSectionHeader('Privacy Settings'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
                  subtitle: const Text('Help improve the app with usage analytics'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement analytics toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Analytics ${value ? 'enabled' : 'disabled'}'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.bug_report),
                  title: const Text('Crash Reporting'),
                  subtitle: const Text('Send crash reports to help fix issues'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement crash reporting toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Crash reporting ${value ? 'enabled' : 'disabled'}'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.share),
                  title: const Text('Team Data Sharing'),
                  subtitle: const Text('Allow sharing data with team members'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement team data sharing toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Team data sharing ${value ? 'enabled' : 'disabled'}'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Retention Section
          _buildSectionHeader('Data Retention'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Data Retention Period'),
                  subtitle: const Text('Keep forever'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showRetentionDialog(context);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_delete),
                  title: const Text('Auto-delete Old Receipts'),
                  subtitle: const Text('Automatically delete old receipts based on retention period'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement auto-delete toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Auto-delete ${value ? 'enabled' : 'disabled'}'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data Usage Stats
          _buildSectionHeader('Data Usage'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage),
                      const SizedBox(width: 12),
                      const Text(
                        'Storage Usage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Receipts', '0'),
                  _buildStatRow('Claims', '0'),
                  _buildStatRow('Storage Used', '0 MB'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data as $format'),
        content: Text(
          'This will export all your data in $format format. The file will be saved to your device and you can share it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement data export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exporting data as $format...'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showRetentionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Keep forever'),
              value: 'forever',
              groupValue: 'forever',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('1 year'),
              value: '1year',
              groupValue: 'forever',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('6 months'),
              value: '6months',
              groupValue: 'forever',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('3 months'),
              value: '3months',
              groupValue: 'forever',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data retention period updated'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
