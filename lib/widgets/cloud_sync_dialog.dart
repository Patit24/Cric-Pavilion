import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/mock_database.dart';
import '../services/server_sync_service.dart';
import '../services/database_persistence_service.dart';
import 'dart:convert';
import '../theme/neo_glass_theme.dart';

/// Dialog allowing users to view server sync status, trigger manual sync,
/// and export/import match backups across mobile and desktop devices.
class CloudSyncDialog extends StatefulWidget {
  const CloudSyncDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CloudSyncDialog(),
    );
  }

  @override
  State<CloudSyncDialog> createState() => _CloudSyncDialogState();
}

class _CloudSyncDialogState extends State<CloudSyncDialog> {
  bool _isSyncing = false;
  String? _syncMessage;
  bool _isError = false;
  final TextEditingController _importJsonController = TextEditingController();
  bool _showImportBox = false;

  Future<void> _performSync(MockDatabase db) async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    final success = await ServerSyncService.syncWithServer(db);

    setState(() {
      _isSyncing = false;
      if (success) {
        _isError = false;
        _syncMessage = 'Sync successful! ${db.matches.length} matches synchronized across devices.';
      } else {
        _isError = true;
        _syncMessage = ServerSyncService.lastSyncStatus;
      }
    });
  }

  void _exportJson(MockDatabase db) {
    final jsonStr = DatabasePersistenceService.exportDatabaseToJson(db);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database JSON copied to clipboard! You can paste it into any device.'),
        backgroundColor: Color(0xFF009270),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _importJson(MockDatabase db) {
    final raw = _importJsonController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste valid JSON data to import.')),
      );
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON Object');
      }
      final changed = DatabasePersistenceService.mergeMapIntoDatabase(db, decoded);
      if (changed) {
        db.notifyListeners();
        // Also push to central server
        ServerSyncService.pushInBackground(db);
        setState(() {
          _showImportBox = false;
          _syncMessage = 'Successfully imported data into database!';
          _isError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported! Total matches: ${db.matches.length}'),
            backgroundColor: const Color(0xFF009270),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new matches or records found in the imported data.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<MockDatabase>(context);
    final baseUrl = ServerSyncService.getBaseUrl();
    final lastTime = ServerSyncService.lastSyncTime;
    final timeStr = lastTime != null
        ? DateFormat('hh:mm:ss a, MMM d').format(lastTime)
        : 'Never (Tap Sync to connect)';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x3300F5A0), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_sync, color: Color(0xFF00F5A0), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cross-Device Synchronization',
                            style: TextStyle(color: GlassTokens.inkPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sync matches between mobile phone & desktop',
                            style: TextStyle(color: GlassTokens.inkPrimary.withValues(alpha: 0.6), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: GlassTokens.inkSecondary, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Server Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: GlassTokens.bgLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlassTokens.glassHairline),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Central Sync Server', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00F5A0),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                baseUrl,
                                style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: GlassTokens.glassHairline, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Last Synchronized', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                          Text(
                            timeStr,
                            style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Local Matches on this Device', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 12)),
                          Text(
                            '${db.matches.length} Matches',
                            style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Feedback Message if any
                if (_syncMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF009270).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isError ? Colors.red.withValues(alpha: 0.4) : const Color(0xFF00F5A0).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError ? Icons.warning_amber : Icons.check_circle,
                          color: _isError ? Colors.redAccent : const Color(0xFF00F5A0),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _syncMessage!,
                            style: TextStyle(
                              color: _isError ? Colors.redAccent : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : () => _performSync(db),
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.sync, color: Colors.black, size: 18),
                  label: Text(
                    _isSyncing ? 'Synchronizing...' : 'Sync With Central Server Now ⚡',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5A0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Explanation note for mobile users
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If you scored a match on your phone, open the app on your phone and tap "Sync Now". This uploads the match to the central server so your desktop receives it immediately.',
                          style: TextStyle(color: GlassTokens.inkPrimary.withValues(alpha: 0.8), fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary manual Transfer options
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportJson(db),
                        icon: const Icon(Icons.copy, size: 14, color: GlassTokens.inkSecondary),
                        label: const Text('Export / Copy Data', style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GlassTokens.glassHairline),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showImportBox = !_showImportBox;
                          });
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 14, color: GlassTokens.inkSecondary),
                        label: Text(
                          _showImportBox ? 'Hide Import' : 'Import / Restore',
                          style: const TextStyle(color: GlassTokens.inkSecondary, fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GlassTokens.glassHairline),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Import Text Area
                if (_showImportBox) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GlassTokens.bgLightBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: GlassTokens.glassHairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Paste Backup JSON from Mobile:',
                          style: TextStyle(color: GlassTokens.inkSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _importJsonController,
                          maxLines: 4,
                          style: const TextStyle(color: GlassTokens.inkPrimary, fontSize: 11, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: '{"version": 1, "matches": [...]}',
                            hintStyle: const TextStyle(color: GlassTokens.glassHairline, fontSize: 11),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _importJson(db),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009270),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Merge into Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
