import 'package:flutter/material.dart';
import '../widgets/gradient_scaffold.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSection(
            context,
            '1️⃣ Data We Collect',
            [
              'Email Address (for authentication)',
              'Journal Entries (encrypted)',
              'Mood Emojis',
              'AI-Enhanced Content (user-initiated only)',
            ],
          ),
          _buildSection(
            context,
            '2️⃣ How We Use Data',
            [
              'To securely store your journals',
              'To analyze mood trends',
              'To generate AI enhancements (only when requested)',
              'We NEVER sell your data',
            ],
          ),
          _buildSection(
            context,
            '3️⃣ AI Processing (Groq)',
            [
              'Text is sent securely to Groq for processing',
              'Data is NOT used to train AI models',
              'Processing is temporary and stateless',
            ],
          ),
          _buildSection(
            context,
            '4️⃣ Security Measures',
            [
              'Industry-standard Firebase Authentication',
              'HTTPS encryption for all data transit',
              'Secure Cloud Firestore database storage',
            ],
          ),
          _buildSection(
            context,
            '5️⃣ Your Rights',
            [
              'Delete any entry instantly',
              'Request full account deletion',
              'Export your data anytime',
            ],
          ),
          _buildSection(
            context,
            '6️⃣ Contact Us',
            [
              'Questions? Email: support@aijournal.app',
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
