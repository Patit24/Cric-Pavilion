import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/mock_database.dart';

class RoleSwitcherChip extends StatelessWidget {
  final bool compact;

  const RoleSwitcherChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<MockDatabase>();
    final role = db.currentRole;
    final team = db.currentAuthenticatedTeam;

    return InkWell(
      onTap: () => _showRoleSelectionSheet(context, db),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 6),
        decoration: BoxDecoration(
          color: role.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: role.color.withValues(alpha: 0.8), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role.icon, size: 14, color: role.color),
            const SizedBox(width: 6),
            Text(
              compact
                  ? (role == AppUserRole.teamOwner && team != null
                      ? team.shortName
                      : role.shortDisplayName)
                  : (role == AppUserRole.teamOwner && team != null
                      ? '${role.displayName} (${team.shortName})'
                      : role.displayName),
              style: TextStyle(
                color: role.color,
                fontSize: compact ? 10.5 : 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: role.color),
          ],
        ),
      ),
    );
  }

  void _showRoleSelectionSheet(BuildContext context, MockDatabase db) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.switch_account, color: Color(0xFF34D399), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Switch User Persona / Role',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Preview the app from each user perspective. Permissions and UI dashboards adapt automatically.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // All RBAC Roles
                    ...[
                      AppUserRole.superAdmin,
                      AppUserRole.tournamentAdmin,
                      AppUserRole.auctioneer,
                      AppUserRole.auctionOperator,
                      AppUserRole.teamOwner,
                      AppUserRole.player,
                      AppUserRole.viewer,
                    ].map((role) {
                      final isSelected = db.currentRole == role;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            if (role == AppUserRole.teamOwner && db.teams.isNotEmpty) {
                              _showTeamPickerSubDialog(context, db);
                            } else if (role == AppUserRole.player && db.players.isNotEmpty) {
                              _showPlayerPickerSubDialog(context, db);
                            } else {
                              db.setRole(role);
                              Navigator.pop(ctx);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? role.color.withValues(alpha: 0.15)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? role.color : Colors.white10,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: role.color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(role.icon, color: role.color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            role.displayName,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: role.color.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              role.badge,
                                              style: TextStyle(
                                                color: role.color,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        role.description,
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: role.color, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTeamPickerSubDialog(BuildContext context, MockDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.business_center, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 8),
              Text('Select Franchise Team', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: db.teams.length,
              itemBuilder: (ctx, i) {
                final team = db.teams[i];
                final isCurrent = db.authenticatedTeamId == team.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(team.logoUrl),
                    radius: 16,
                  ),
                  title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Purse: ₹${(team.purseRemaining / 100000).toStringAsFixed(1)}L • Code: ${team.uniqueTeamCode}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: isCurrent ? const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18) : null,
                  onTap: () {
                    db.setRole(AppUserRole.teamOwner, teamId: team.id);
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Close bottom sheet
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPlayerPickerSubDialog(BuildContext context, MockDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.person, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text('Select Player Persona', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: db.players.take(15).length,
              itemBuilder: (ctx, i) {
                final player = db.players[i];
                final isCurrent = db.authenticatedPlayerId == player.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(player.photoUrl),
                    radius: 16,
                  ),
                  title: Text(player.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${player.roleString} • Base: ₹${player.basePrice} • Status: ${player.auctionStatus.displayName}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: isCurrent ? const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18) : null,
                  onTap: () {
                    db.setRole(AppUserRole.player, playerId: player.id);
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
