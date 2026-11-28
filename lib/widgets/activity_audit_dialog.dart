import 'package:flutter/material.dart';
import '../../services/mock_database.dart';
import '../theme/neo_glass_theme.dart';

class ActivityAuditDialog extends StatefulWidget {
  final MockDatabase db;

  const ActivityAuditDialog({super.key, required this.db});

  @override
  State<ActivityAuditDialog> createState() => _ActivityAuditDialogState();
}

class _ActivityAuditDialogState extends State<ActivityAuditDialog> {
  String selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final allLogs = widget.db.auditLogs;
    final filteredLogs = selectedCategory == 'all'
        ? allLogs
        : allLogs.where((l) => l.category.toLowerCase() == selectedCategory.toLowerCase()).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: GlassTokens.bgLightBlue),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 550,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009270).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF059669)),
                    ),
                    child: const Icon(Icons.receipt_long, color: Color(0xFF34D399), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM AUDIT & ACTIVITY LOG',
                          style: TextStyle(
                            color: GlassTokens.inkPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Real-time transaction & operational history',
                          style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'tournament', 'auction', 'scoring'].map((cat) {
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          cat == 'all' ? 'All (${allLogs.length})' : cat.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : GlassTokens.inkSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF34D399),
                        backgroundColor: GlassTokens.bgLightBlue,
                        onSelected: (val) => setState(() => selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Audit Logs List or Empty State
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: GlassTokens.bgLightBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: GlassTokens.glassHairline),
                                ),
                                child: const Icon(Icons.history_toggle_off, color: GlassTokens.inkMuted, size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Activities Recorded Yet',
                                style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Actions like organizing a tournament, bidding in auctions, or scoring deliveries will be recorded here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          Color catColor;
                          switch (log.category.toLowerCase()) {
                            case 'tournament':
                              catColor = const Color(0xFF059669);
                              break;
                            case 'auction':
                              catColor = Colors.amber;
                              break;
                            case 'scoring':
                              catColor = const Color(0xFF0284C7);
                              break;
                            default:
                              catColor = Colors.purpleAccent;
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GlassTokens.bgLightBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: GlassTokens.glassHairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: catColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        log.category.toUpperCase(),
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(log.timestamp),
                                      style: const TextStyle(color: GlassTokens.inkMuted, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log.action,
                                  style: const TextStyle(
                                    color: GlassTokens.inkPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  log.details,
                                  style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                                ),
                                if (log.performedBy.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 11, color: GlassTokens.inkMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        'By: ${log.performedBy} (${log.role})',
                                        style: const TextStyle(color: GlassTokens.inkMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009270),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text('Close Audit View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
