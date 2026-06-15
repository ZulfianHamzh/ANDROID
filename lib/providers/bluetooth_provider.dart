import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter/foundation.dart';

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  // Initialize immediately so it's ready when widgets need it
  service.initialize().then((_) {
    debugPrint('[Bluetooth Provider] Service initialized');
  }).catchError((e) {
    debugPrint('[Bluetooth Provider] Init error: $e');
  });
  return service;
});

/// Stream provider that emits connection status (initially false, then live updates)
final bluetoothStatusProvider = StreamProvider<bool>((ref) async* {
  final bluetooth = ref.watch(bluetoothServiceProvider);
  // Emit initial connection state first (before waiting for stream subscription)
  yield bluetooth.isConnected;
  // Then subscribe to live updates
  await for (final status in bluetooth.statusStream) {
    yield status;
  }
});

/// Stream provider that emits paired devices list
final bluetoothDevicesProvider = StreamProvider<List<BluetoothPrinterDevice>>((ref) async* {
  final bluetooth = ref.watch(bluetoothServiceProvider);
  // Wait for initialization
  await bluetooth.initialize();
  // Emit currently known devices first
  yield bluetooth.pairedDevices;
  // Then fetch fresh data
  await bluetooth.getPairedDevices();
  // Subscribe to live updates
  await for (final devices in bluetooth.devicesStream) {
    yield devices;
  }
});

/// Provider that emits current connected device whenever connection status changes
final connectedBluetoothDeviceProvider = StreamProvider<BluetoothPrinterDevice?>((ref) async* {
  final bluetooth = ref.watch(bluetoothServiceProvider);
  // Emit initial state
  yield bluetooth.connectedDevice;
  // Subscribe to connection changes
  await for (final _ in bluetooth.statusStream) {
    yield bluetooth.connectedDevice;
  }
});
