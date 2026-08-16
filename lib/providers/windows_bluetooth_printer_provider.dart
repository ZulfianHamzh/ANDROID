import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_thermal_printer_windows/flutter_thermal_printer_windows.dart'
    as tp;
import '../services/windows_bluetooth_printer_service.dart';

final windowsBluetoothPrinterServiceProvider =
    Provider<WindowsBluetoothPrinterService>((ref) {
  return WindowsBluetoothPrinterService();
});

/// Stream provider that emits Bluetooth thermal connection status on Windows
/// (initially the current state, then live updates).
final windowsBluetoothStatusProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(windowsBluetoothPrinterServiceProvider);
  yield service.isConnected;
  await for (final status in service.statusStream) {
    yield status;
  }
});

/// Stream provider that emits paired Bluetooth thermal printers on Windows.
/// Re-emits whenever the connection status changes so pairing updates appear.
final windowsBluetoothPairedDevicesProvider =
    StreamProvider<List<tp.BluetoothPrinter>>((ref) async* {
  final service = ref.watch(windowsBluetoothPrinterServiceProvider);
  yield await service.getPairedPrinters();
  await for (final _ in service.statusStream) {
    yield await service.getPairedPrinters();
  }
});
