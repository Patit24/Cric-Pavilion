import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_persistence_service.dart';
import 'mock_database.dart';

/// Centralized synchronization service between mobile clients, desktop browsers,
/// and the central CricPavilion server.
class ServerSyncService {
  static const String _keyServerUrl = 'cricpavilion_custom_server_url';
  static bool isSyncing = false;
  static DateTime? lastSyncTime;
  static String lastSyncStatus = 'Idle';
  static int syncCount = 0;

  /// Resolves the base URL for the sync server.
  /// On Web, defaults to current host origin (e.g. http://192.168.1.5:8080 or http://localhost:8080).
  static String getBaseUrl() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file://')) {
        return origin;
      }
    }
    return 'http://localhost:8080';
  }

  /// Two-way sync: Pushes local database state to central server and merges any
  /// server-side matches/scorecards back into the local device storage.
  static Future<bool> syncWithServer(MockDatabase db, {String? customUrl}) async {
    if (isSyncing) return false;
    isSyncing = true;
    lastSyncStatus = 'Syncing...';

    try {
      final base = (customUrl != null && customUrl.isNotEmpty) ? customUrl : getBaseUrl();
      final syncUri = Uri.parse('$base/api/sync');

      final localPayload = DatabasePersistenceService.exportDatabaseToMap(db);
      final body = jsonEncode(localPayload);

      final response = await http
          .post(
            syncUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final changed = DatabasePersistenceService.mergeMapIntoDatabase(db, responseData);
        lastSyncTime = DateTime.now();
        syncCount++;
        lastSyncStatus = 'Synced successfully (${db.matches.length} matches)';
        if (changed) {
          db.notifyListeners();
        }
        isSyncing = false;
        return true;
      } else {
        lastSyncStatus = 'Server error (${response.statusCode})';
      }
    } catch (e) {
      lastSyncStatus = 'Sync unreachable: $e';
      if (!e.toString().contains('ClientException') && !e.toString().contains('Failed to fetch')) {
        debugPrint('ServerSyncService error: $e');
      }
    } finally {
      isSyncing = false;
    }
    return false;
  }

  /// Background push to server after match events (ball bowled, match started, etc.)
  static void pushInBackground(MockDatabase db) {
    Future.microtask(() async {
      await syncWithServer(db);
    });
  }

  /// Pulls latest state from server without overwriting local unpersisted changes
  static Future<bool> pullFromServer(MockDatabase db, {String? customUrl}) async {
    try {
      final base = (customUrl != null && customUrl.isNotEmpty) ? customUrl : getBaseUrl();
      final syncUri = Uri.parse('$base/api/sync');

      final response = await http.get(
        syncUri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final changed = DatabasePersistenceService.mergeMapIntoDatabase(db, responseData);
        lastSyncTime = DateTime.now();
        lastSyncStatus = 'Updated from server';
        if (changed) {
          db.notifyListeners();
        }
        return true;
      }
    } catch (e) {
      lastSyncStatus = 'Pull error: $e';
    }
    return false;
  }

  /// Saves custom server URL to local preferences (e.g. for testing custom IP)
  static Future<void> setCustomServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  /// Reads custom server URL from local preferences
  static Future<String?> getCustomServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }
}
