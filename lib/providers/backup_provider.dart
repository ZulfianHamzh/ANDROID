import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../backup/backup_service.dart';
import 'pos_provider.dart' show supabaseServiceProvider;

/// State for backup operations.
class BackupState {
  final bool isRunning;
  final String? currentMessage;
  final String? errorMessage;
  final bool isSuccess;
  final Map<String, int>? result;

  const BackupState({
    this.isRunning = false,
    this.currentMessage,
    this.errorMessage,
    this.isSuccess = false,
    this.result,
  });

  BackupState copyWith({
    bool? isRunning,
    String? currentMessage,
    String? errorMessage,
    bool? isSuccess,
    Map<String, int>? result,
  }) {
    return BackupState(
      isRunning: isRunning ?? this.isRunning,
      currentMessage: currentMessage ?? this.currentMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      result: result ?? this.result,
    );
  }
}

class BackupProvider extends StateNotifier<BackupState> {
  final SupabaseService _supabase;

  BackupProvider(this._supabase) : super(const BackupState());

  Future<void> runBackup({required String appVersion}) async {
    if (state.isRunning) return;

    debugPrint('[BackupProvider] Starting backup...');
    state = const BackupState(isRunning: true);

    final service = BackupService(_supabase);

    try {
      final result = await service.runBackup(
        appVersion: appVersion,
        onProgress: (message) {
          state = state.copyWith(currentMessage: message);
          debugPrint('[BackupProvider] $message');
        },
      );

      state = BackupState(
        isSuccess: true,
        result: result,
        currentMessage: 'Backup berhasil!',
      );
      debugPrint('[BackupProvider] Backup completed: $result');
    } catch (e) {
      state = BackupState(
        isRunning: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      debugPrint('[BackupProvider] Backup failed: $e');
    }
  }

  Future<Map<String, dynamic>> getBackupInfo() async {
    final service = BackupService(_supabase);
    return await service.getBackupInfo();
  }

  void reset() {
    state = const BackupState();
  }
}

final backupProvider = StateNotifierProvider<BackupProvider, BackupState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return BackupProvider(supabase);
});
