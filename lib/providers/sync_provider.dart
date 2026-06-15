import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

enum SyncStatus { idle, syncing, pending, error }

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final String? lastError;
  final int syncedCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastError,
    this.syncedCount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
    int? syncedCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: lastError ?? this.lastError,
      syncedCount: syncedCount ?? this.syncedCount,
    );
  }
}

class SyncProvider extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncProvider(this._syncService) : super(const SyncState());

  Future<void> checkPendingCount() async {
    final count = await _syncService.getPendingCount();
    state = state.copyWith(
      pendingCount: count,
      status: count > 0 ? SyncStatus.pending : SyncStatus.idle,
    );
  }

  Future<void> syncAll() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, lastError: null);
    
    try {
      final result = await _syncService.syncAll();
      state = state.copyWith(
        status: SyncStatus.idle,
        pendingCount: 0,
        syncedCount: state.syncedCount + result,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

final syncProvider = StateNotifierProvider<SyncProvider, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncProvider(syncService);
});
