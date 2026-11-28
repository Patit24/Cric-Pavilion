import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/mock_database.dart';
import '../theme/neo_glass_theme.dart';
import 'auth_modal_dialog.dart';
import 'privacy_policy_dialog.dart';
import 'google_auth_setup_dialog.dart';

class AccountAuthPill extends StatelessWidget {
  final bool compact;

  const AccountAuthPill({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final isAuth = db.isAuthenticated;
    final user = db.currentUser;
    final role = db.currentRole;

    if (!isAuth) {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => const AuthModalDialog(),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 5),
          decoration: BoxDecoration(
            color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeoGlassTheme.neonEmerald.withValues(alpha: 0.6), width: 1.2),
            boxShadow: [
              NeoGlassTheme.neoDarkShadow,
              NeoGlassTheme.neoGlowShadow(NeoGlassTheme.neonEmerald, opacity: 0.15),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 12, color: NeoGlassTheme.neonEmerald),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  compact ? 'Login' : 'Organizer Login',
                  style: const TextStyle(
                    color: NeoGlassTheme.neonEmerald,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final firstName = user?.fullName.split(' ').first ?? 'User';

    return InkWell(
      onTap: () => _showUserProfileSheet(context, db),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 5),
        decoration: BoxDecoration(
          color: role.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: role.color.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            NeoGlassTheme.neoDarkShadow,
            NeoGlassTheme.neoGlowShadow(role.color, opacity: 0.2),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 6),
            Text(
              compact ? '$firstName (${role.shortDisplayName})' : '${user?.fullName} • ${role.shortDisplayName}',
              style: TextStyle(
                color: role.color,
                fontSize: compact ? 10.5 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: role.color),
          ],
        ),
      ),
    );
  }

  void _showUserProfileSheet(BuildContext context, MockDatabase db) {
    final user = db.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: NeoGlassTheme.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: NeoGlassTheme.glassBorder),
            boxShadow: [NeoGlassTheme.neoDarkShadow],
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: NeoGlassTheme.neonEmerald, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: GlassTokens.bgLightBlue,
                      child: Icon(Icons.person, color: NeoGlassTheme.neonEmerald, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${user.email} • ${user.mobileNumber}',
                          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Roles & Memberships
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x330F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GlassTokens.glassHairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR AUTHORIZED TOURNAMENT ROLES:',
                      style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 8),
                    if (user.tournamentRoles.isEmpty && user.ownedTeamIds.isEmpty && user.conductorAuctionIds.isEmpty)
                      const Text(
                        'No organizer roles assigned yet. You can create a tournament or join an auction with an Auction PIN.',
                        style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                      )
                    else ...[
                      if (user.tournamentRoles.isNotEmpty)
                        ...user.tournamentRoles.entries.map((e) {
                          final tourn = db.getTournament(e.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, size: 14, color: e.value.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${tourn?.name ?? "Tournament"}: ${e.value.displayName}',
                                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (user.ownedTeamIds.isNotEmpty)
                        ...user.ownedTeamIds.map((tId) {
                          final team = db.getTeam(tId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.business_center, size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Franchise Owner: ${team?.name ?? tId}',
                                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (user.conductorAuctionIds.isNotEmpty)
                        ...user.conductorAuctionIds.map((aId) {
                          final auc = db.getAuction(aId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.gavel, size: 14, color: Color(0xFFEA580C)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Auction Conductor: ${auc.title}',
                                    style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Two-Factor Authentication (Google Authenticator) Tile
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  GoogleAuthSetupDialog.show(context, user);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: (user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isGoogleAuthEnabled ? Icons.verified_user : Icons.security_outlined,
                        size: 20,
                        color: user.isGoogleAuthEnabled ? NeoGlassTheme.neonEmerald : NeoGlassTheme.neonCyan,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isGoogleAuthEnabled ? 'Google Authenticator 2FA: Active' : 'Google Authenticator (2FA)',
                              style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.isGoogleAuthEnabled
                                  ? 'RFC 6238 TOTP verified • Tap to manage'
                                  : 'Tap to configure 6-digit TOTP app verification',
                              style: TextStyle(
                                color: user.isGoogleAuthEnabled ? const Color(0xFF00F5A0) : GlassTokens.inkSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: user.isGoogleAuthEnabled ? const Color(0xFF064E3B) : GlassTokens.bgLightBlue,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: user.isGoogleAuthEnabled ? const Color(0xFF10B981) : GlassTokens.glassHairline,
                          ),
                        ),
                        child: Text(
                          user.isGoogleAuthEnabled ? 'ON' : 'SETUP',
                          style: TextStyle(
                            color: user.isGoogleAuthEnabled ? const Color(0xFF10B981) : GlassTokens.inkSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Privacy Policy Link (Google Play Compliance)
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  PrivacyPolicyDialog.show(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.privacy_tip_outlined, size: 14, color: Color(0xFF00F5A0)),
                      SizedBox(width: 6),
                      Text(
                        'Privacy Policy & Data Rights',
                        style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Sign Out Button
              NeoGlassButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  db.logoutUser();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out. Returned to Public Viewer mode.'),
                      backgroundColor: GlassTokens.bgLightBlue,
                    ),
                  );
                },
                gradient: const LinearGradient(
                  colors: [Color(0xFF334155), GlassTokens.bgLightBlue],
                ),
                icon: Icons.logout,
                child: const Text('Sign Out (Return to Public View)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 10),

              // Permanent Account Deletion Button (Google Play User Data Compliance)
              TextButton.icon(
                onPressed: () => _confirmAccountDeletion(context, db, user),
                icon: const Icon(Icons.delete_forever, size: 14, color: Colors.redAccent),
                label: const Text(
                  'Delete Account & Personal Data',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmAccountDeletion(BuildContext context, MockDatabase db, UserAccount user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete account "${user.fullName}" (${user.mobileNumber})? All associated personal records will be erased.',
          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: GlassTokens.inkSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              db.deleteUserAccount(user.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account & personal data deleted successfully.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
