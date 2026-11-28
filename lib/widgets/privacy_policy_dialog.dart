import 'package:flutter/material.dart';
import '../theme/neo_glass_theme.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const PrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GlassTokens.bgLightBlue),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: Color(0xFF00F5A0), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: GlassTokens.inkPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Effective Date: April 2026 • Google Play Compliant',
                style: TextStyle(color: GlassTokens.inkMuted, fontSize: 11),
              ),
              const Divider(color: GlassTokens.glassHairline, height: 20),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Overview & Transparency'),
                      _buildParagraph(
                        'CricPavilion ("we", "our", or "us") respects your privacy and is committed to protecting your personal data in accordance with Google Play Developer Program Policies. This privacy policy describes how we collect, store, and protect your information.',
                      ),
                      const SizedBox(height: 14),

                      _buildSectionTitle('2. Information We Collect'),
                      _buildBulletPoint('Personal Identifiers: Full name and contact mobile number provided during optional registration.'),
                      _buildBulletPoint('Player Career Data: Batting, bowling, and fielding scores generated during certified tournament matches.'),
                      _buildBulletPoint('Device & Session Data: Non-sensitive device identifiers used strictly to prevent unauthorized PIN tampering or fraud during live auctions.'),
                      const SizedBox(height: 14),

                      _buildSectionTitle('3. Purpose of Data Processing'),
                      _buildBulletPoint('Facilitating tournament organization, match scheduling, and public ball-by-ball score broadcast.'),
                      _buildBulletPoint('Authenticating franchise team owners and scorers using 6-digit room PIN verification.'),
                      _buildBulletPoint('Maintaining immutable match records, leaderboards, and Orange/Purple Cap standings.'),
                      const SizedBox(height: 14),

                      _buildSectionTitle('4. User Rights & Account Deletion'),
                      _buildParagraph(
                        'In compliance with Google Play User Data policies, any registered user can permanently delete their account and associated personal data at any time directly through the app settings or by contacting our data protection officer.',
                      ),
                      const SizedBox(height: 14),

                      _buildSectionTitle('5. Data Security & Storage'),
                      _buildParagraph(
                        'All transmission of user data is encrypted using industry-standard TLS protocols. We never sell, rent, or trade your personal information to third parties or advertising brokers.',
                      ),
                      const SizedBox(height: 14),

                      _buildSectionTitle('6. Contact & Support'),
                      _buildParagraph(
                        'For questions or privacy requests regarding your data, contact us at privacy@cricpavilion.com.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009270),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00F5A0),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 12, height: 1.45),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
