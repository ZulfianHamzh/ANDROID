import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/thermal_printer_service.dart';

final thermalPrinterServiceProvider = Provider<ThermalPrinterService>((ref) {
  return ThermalPrinterService();
});

final printerReadyProvider = StateProvider<bool>((ref) {
  // Will be updated by connection status
  return false;
});
