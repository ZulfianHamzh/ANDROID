import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Provider to watch network connectivity status
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Emit initial state
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  
  // Emit on changes
  await for (final result in connectivity.onConnectivityChanged) {
    final isOnline = !result.contains(ConnectivityResult.none);
    debugPrint('[Connectivity] Status changed: ${isOnline ? 'ONLINE' : 'OFFLINE'}');
    yield isOnline;
  }
});
