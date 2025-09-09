import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.indigo.shade700],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Mataresit - AI-Powered Receipt Management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Effective Date: January 15, 2025',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Last Updated: January 15, 2025',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Introduction Section
            _buildSection(context, 'Introduction', Icons.info_outline, Colors.blue, [
              'Mataresit ("we," "our," or "us") is committed to protecting your privacy and ensuring the security of your personal and financial data. This Privacy Policy explains how we collect, use, process, and protect your information when you use our AI-powered receipt management platform.',
              'Our service transforms receipts into organized data using advanced artificial intelligence, enabling automated expense tracking, categorization, and financial reporting for businesses of all sizes.',
              'By using Mataresit, you consent to the practices described in this Privacy Policy.',
            ]),

            const SizedBox(height: AppConstants.largePadding),

            // Information We Collect Section
            _buildSection(
              context,
              'Information We Collect',
              Icons.storage,
              Colors.green,
              [],
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Information categories
            _buildInfoCard(
              context,
              'Account Information',
              Icons.person_outline,
              Colors.green,
              [
                'Email Address: For account creation and communication',
                'Password: Securely hashed and stored',
                'Authentication Data: Google OAuth tokens when using Google sign-in',
                'Account Settings: Preferences, categories, and configurations',
              ],
            ),

            const SizedBox(height: AppConstants.smallPadding),

            _buildInfoCard(
              context,
              'Receipt Data',
              Icons.receipt_outlined,
              Colors.purple,
              [
                'Receipt Images: Photos and scanned documents you upload',
                'Extracted Information: Merchant names, dates, amounts, line items',
                'Categories: Expense classifications and tags',
                'Metadata: Upload timestamps, processing status, confidence scores',
              ],
            ),

            const SizedBox(height: AppConstants.smallPadding),

            _buildInfoCard(
              context,
              'Usage Analytics',
              Icons.bar_chart_outlined,
              Colors.orange,
              [
                'Platform Usage: Features accessed, frequency of use',
                'Processing Statistics: Receipt volumes, AI model performance',
                'Error Logs: Technical issues for service improvement',
                'Performance Metrics: Response times, accuracy scores',
              ],
            ),

            const SizedBox(height: AppConstants.smallPadding),

            _buildInfoCard(
              context,
              'Payment Information',
              Icons.credit_card_outlined,
              Colors.red,
              [
                'Billing Details: Name, billing address',
                'Payment Processing: Handled securely by Stripe',
                'Transaction Records: Subscription history, invoices',
                'Usage Tracking: Monthly limits, overage monitoring',
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // AI Processing Section
            _buildSection(
              context,
              'AI Processing and Third-Party Services',
              Icons.smart_toy_outlined,
              Colors.indigo,
              [
                'We use Google Gemini AI for receipt processing with enterprise-grade security.',
                'Data is transmitted via encrypted connections with no long-term storage by Google.',
                'Optional OpenRouter integration requires user-provided API keys.',
                'All payment processing is handled securely by Stripe.',
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // How We Use Your Information Section
            _buildSection(
              context,
              'How We Use Your Information',
              Icons.settings_outlined,
              Colors.purple,
              [
                'Service Provision: AI-powered receipt processing and data extraction',
                'Analytics & Improvement: Service performance monitoring and AI model improvements',
                'Communication: Account notifications, billing communications, and support',
                'Security: Fraud prevention and system security monitoring',
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Data Security Section
            _buildSection(
              context,
              'Data Storage and Security',
              Icons.shield_outlined,
              Colors.red,
              [
                'Bank-Level Security: SOC 2 compliant with enterprise-grade protection',
                'End-to-end encryption for all data transmission and storage',
                'Secure cloud infrastructure with role-based access control',
                'Regular security assessments and vulnerability testing',
                'Data retention: Receipt data (7 years), Account data (lifetime), Usage logs (2 years)',
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Your Rights Section
            _buildSection(
              context,
              'Your Rights and Controls',
              Icons.verified_user_outlined,
              Colors.blue,
              [
                'Access Rights: Request access to all personal data we hold',
                'Correction Rights: Update or correct inaccurate information',
                'Deletion Rights: Request deletion of your personal data',
                'Portability Rights: Export your data in structured formats',
                'Restriction Rights: Limit how we process your data',
                'Objection Rights: Object to certain types of processing',
              ],
            ),

            const SizedBox(height: AppConstants.largePadding),

            // Contact Information Section
            _buildContactSection(context),

            const SizedBox(height: AppConstants.largePadding),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> content,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              ...content.map(
                (text) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.smallPadding,
                  ),
                  child: Text(
                    text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Card(
      color: color.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_support,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Icon(Icons.headset_mic, color: Colors.green.shade600, size: 32),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Protection & Privacy Inquiries',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                      ),
                      Text(
                        'We\'re here to help with all your privacy-related questions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    'Email Contact',
                    Icons.email,
                    'privacy@mataresit.com',
                    'Response time: Within 72 hours',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildContactCard(
                    context,
                    'General Support',
                    Icons.headset_mic,
                    'support@mataresit.com',
                    'Response time: Within 24 hours',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    String title,
    IconData icon,
    String email,
    String responseTime,
    Color color,
  ) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              responseTime,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: AppConstants.smallPadding),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mataresit Privacy Policy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Effective Date: January 15, 2025',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Divider(),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'This Privacy Policy is part of our commitment to transparency and data protection.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              '© 2025 Mataresit. All rights reserved. This document is governed by Malaysian privacy laws and international best practices.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSecurityBadge(context, Icons.verified, 'SOC 2 Compliant'),
                _buildSecurityBadge(context, Icons.lock, 'Bank-Level Security'),
                _buildSecurityBadge(context, Icons.shield, 'Enterprise Grade'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
