import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_database.dart';
import '../screens/tournaments/create_tournament_dialog.dart';
import '../screens/matches/create_direct_match_dialog.dart';
import 'auth_modal_dialog.dart';
import 'mobile_otp_verification_dialog.dart';
import '../theme/neo_glass_theme.dart';

class OrganizeHubModal extends StatelessWidget {
  const OrganizeHubModal({super.key});

  static void show(BuildContext context) {
    final db = Provider.of<MockDatabase>(context, listen: false);

    // 1. Mandatory Login Check
    if (!db.isAuthenticated) {
      showDialog(
        context: context,
        builder: (ctx) => AuthModalDialog(
          onAuthSuccess: () {
            // Once logged in, check mobile verification
            if (db.currentUser?.isMobileVerified != true) {
              showDialog(
                context: context,
                builder: (mCtx) => MobileOtpVerificationDialog(
                  onVerified: () => _openModal(context, db),
                ),
              );
            } else {
              _openModal(context, db);
            }
          },
        ),
      );
      return;
    }

    // 2. Mandatory Mobile Verification Check
    if (db.currentUser?.isMobileVerified != true) {
      showDialog(
        context: context,
        builder: (ctx) => MobileOtpVerificationDialog(
          onVerified: () => _openModal(context, db),
        ),
      );
      return;
    }

    _openModal(context, db);
  }

  static void _openModal(BuildContext context, MockDatabase db) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const OrganizeHubModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<MockDatabase>(context);

    return Container(
      decoration: const BoxDecoration(
        color: GlassTokens.inkPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x3300F5A0), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GlassTokens.glassHairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, color: Color(0xFF00F5A0), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organize / Host',
                      style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Choose a cricket workflow to begin',
                      style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Organize Tournament
          _buildOptionCard(
            context: context,
            icon: Icons.emoji_events,
            iconColor: const Color(0xFF00F5A0),
            title: 'Organize Cricket Tournament',
            subtitle: 'Multi-team league, franchise auctions, ICC points table, fixtures & Orange/Purple Cap leaderboards.',
            badgeText: 'League & Draft',
            badgeColor: const Color(0xFF00F5A0),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => CreateTournamentDialog(db: db),
              );
            },
          ),
          const SizedBox(height: 14),

          // Option 2: Direct 2-Team Match
          _buildOptionCard(
            context: context,
            icon: Icons.flash_on,
            iconColor: const Color(0xFF00D9F5),
            title: 'Create Direct 2-Team Match',
            subtitle: 'Quick standalone match without creating a tournament. Includes live ball-by-ball scoring & permanent career stats.',
            badgeText: 'Quick Match',
            badgeColor: const Color(0xFF00D9F5),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => CreateDirectMatchDialog(db: db),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: GlassTokens.bgLightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GlassTokens.glassHairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: GlassTokens.inkMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
