import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/windows_printer_service.dart';

final windowsPrinterServiceProvider = Provider<WindowsPrinterService>((ref) {
  return WindowsPrinterService();
});

/// Emits whether a default Windows printer is available.
/// Re-checks periodically so the status stays fresh. Only watched on Windows.
final windowsPrinterReadyProvider = StreamProvider<bool>((ref) async* {
  final printer = ref.watch(windowsPrinterServiceProvider);
  while (true) {
    yield await printer.isPrinterReady;
    await Future<void>.delayed(const Duration(seconds: 10));
  }
});
