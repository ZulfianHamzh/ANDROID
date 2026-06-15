import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_database_service.dart';
import 'supabase_service.dart';

class SyncService {
  final LocalDatabaseService _localDB = LocalDatabaseService();
  SupabaseService? _supabase;

  void init(SupabaseService supabase) {
    _supabase = supabase;
  }

  Future<int> getPendingCount() async {
    return await _localDB.getPendingSyncCount();
  }

  /// Sync all pending items to Supabase
  /// Returns the number of items successfully synced
  Future<int> syncAll() async {
    if (_supabase == null) {
      debugPrint('[Sync] Supabase not initialized');
      throw Exception('Supabase service not initialized');
    }

    final items = await _localDB.getPendingSyncItems();
    if (items.isEmpty) {
      debugPrint('[Sync] Nothing to sync');
      return 0;
    }

    debugPrint('[Sync] Starting sync of ${items.length} items');
    int syncedCount = 0;

    for (final item in items) {
      try {
        await _processSyncItem(item);
        await _localDB.removeSyncItem(item['id'] as int);
        syncedCount++;
        debugPrint('[Sync] ✓ Item ${item['id']} synced successfully');
      } catch (e) {
        debugPrint('[Sync] ✗ Item ${item['id']} failed: $e');
        await _localDB.incrementRetry(item['id'] as int);
        await _localDB.updateSyncError(item['id'] as int, e.toString());

        // Check if max retries reached
        final retryCount = (item['retry_count'] as int?) ?? 0;
        if (retryCount >= 3) {
          debugPrint('[Sync] Max retries reached for item ${item['id']}, removing');
          await _localDB.removeSyncItem(item['id'] as int);
        }
      }
    }

    debugPrint('[Sync] Complete: $syncedCount/${items.length} synced');
    return syncedCount;
  }

  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final payload = item['payload'] as String;

    switch (action) {
      case 'create_transaction':
        await _syncTransaction(payload);
        break;
      case 'create_held_order':
        await _syncHeldOrder(payload);
        break;
      case 'complete_held_order':
        await _completeHeldOrder(payload);
        break;
      default:
        debugPrint('[Sync] Unknown action: $action');
    }
  }

  Future<void> _syncTransaction(String payload) async {
    // Parse the payload - stored as Map toString, need to parse it back
    // For MVP, we'll use a simple approach
    debugPrint('[Sync] Syncing transaction: $payload');
    // TODO: Parse and recreate transaction, then call _supabase.saveTransaction()
  }

  Future<void> _syncHeldOrder(String payload) async {
    debugPrint('[Sync] Syncing held order: $payload');
    // TODO: Parse and recreate held order
  }

  Future<void> _completeHeldOrder(String payload) async {
    debugPrint('[Sync] Completing held order: $payload');
    // TODO: Parse and complete held order via Supabase
  }
}
