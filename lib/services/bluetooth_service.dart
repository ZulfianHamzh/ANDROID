import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothPrinterDevice {
  final String name;
  final String address;
  final bool isConnected;

  BluetoothPrinterDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal();

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  
  BluetoothConnection? _connection;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _connectionStatusSubscription;
  Timer? _reconnectTimer;
  
  bool _isEnabled = false;
  bool _isConnected = false;
  BluetoothPrinterDevice? _connectedDevice;
  final List<BluetoothPrinterDevice> _pairedDevices = [];
  final _statusController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<BluetoothPrinterDevice>>.broadcast();

  // Auto-connect MAC addresses for DHBH printers
  static const List<String> _autoConnectAddresses = [
    '66:12:3F:23:EF:92',
    '66:22:0E:80:81:CC',
  ];

  Stream<bool> get statusStream => _statusController.stream;
  Stream<List<BluetoothPrinterDevice>> get devicesStream => _devicesController.stream;
  
  bool get isConnected => _isConnected;
  bool get isEnabled => _isEnabled;
  BluetoothPrinterDevice? get connectedDevice => _connectedDevice;
  List<BluetoothPrinterDevice> get pairedDevices => List.unmodifiable(_pairedDevices);

  /// Whether Bluetooth thermal printing is supported on this platform.
  /// `flutter_bluetooth_serial` supports Android, iOS, macOS, and Linux —
  /// NOT Windows desktop. On unsupported platforms the service becomes a
  /// safe no-op so the rest of the app keeps working normally.
  static bool get isSupported {
    if (kIsWeb) return false;
    return !Platform.isWindows;
  }

  /// Initialize Bluetooth service with auto-connect to known printers
  Future<void> initialize() async {
    if (!isSupported) {
      debugPrint('[Bluetooth] ⚠️ Bluetooth printing is not supported on this platform (Windows)');
      _isEnabled = false;
      _isConnected = false;
      _statusController.add(false);
      return;
    }

    try {
      _isEnabled = await _bluetooth.isEnabled ?? false;
      debugPrint('[Bluetooth] Initialized: enabled=$_isEnabled');
      
      // Emit initial state
      _statusController.add(false);
      
      // Listen to Bluetooth status changes
      _bluetooth.onStateChanged().listen((state) {
        _isEnabled = state == BluetoothState.STATE_ON;
        debugPrint('[Bluetooth] State changed: ${_isEnabled ? 'ON' : 'OFF'}');
        
        // Auto-reconnect when Bluetooth is turned back on
        if (_isEnabled && !_isConnected) {
          debugPrint('[Bluetooth] Bluetooth enabled, attempting auto-connect...');
          _tryAutoConnect();
        }
        
        _statusController.add(_isConnected);
      });
      
      // Get paired devices and attempt auto-connect
      await getPairedDevices();
      await _tryAutoConnect();
    } catch (e) {
      debugPrint('[Bluetooth] Init error: $e');
      _statusController.add(false);
    }
  }

  /// Try to auto-connect to known printer MAC addresses
  Future<void> _tryAutoConnect() async {
    if (_isConnected) {
      debugPrint('[Bluetooth] Already connected, skipping auto-connect');
      return;
    }

    debugPrint('[Bluetooth] Attempting auto-connect to known printers...');
    
    for (final address in _autoConnectAddresses) {
      debugPrint('[Bluetooth] Checking device: $address');
      
      // Check if this device is in paired devices
      final pairedDevice = _pairedDevices.firstWhere(
        (d) => d.address.toUpperCase() == address.toUpperCase(),
        orElse: () => BluetoothPrinterDevice(name: '', address: ''),
      );
      
      if (pairedDevice.address.isNotEmpty) {
        debugPrint('[Bluetooth] Found paired device: ${pairedDevice.name} ($address)');
        final success = await connect(address);
        if (success) {
          debugPrint('[Bluetooth] ✓ Auto-connected to ${pairedDevice.name}');
          return;
        }
      } else {
        debugPrint('[Bluetooth] Device $address not found in paired devices');
      }
    }
    
    debugPrint('[Bluetooth] Auto-connect failed - no known printers available');
  }

  /// Get paired devices
  Future<void> getPairedDevices() async {
    if (!isSupported) {
      debugPrint('[Bluetooth] Bluetooth printing is not supported on this platform');
      return;
    }

    try {
      if (!_isEnabled) {
        debugPrint('[Bluetooth] Bluetooth not enabled');
        return;
      }

      final devices = await _bluetooth.getBondedDevices();
      _pairedDevices.clear();
      for (var device in devices) {
        _pairedDevices.add(BluetoothPrinterDevice(
          name: device.name ?? 'Unknown Device',
          address: device.address,
        ));
      }
      
      _devicesController.add(_pairedDevices);
      debugPrint('[Bluetooth] Found ${_pairedDevices.length} paired devices');
    } catch (e) {
      debugPrint('[Bluetooth] Error getting paired devices: $e');
    }
  }

  /// Connect to device
  Future<bool> connect(String deviceAddress) async {
    if (!isSupported) {
      debugPrint('[Bluetooth] Bluetooth printing is not supported on this platform');
      return false;
    }

    try {
      if (_isConnected) {
        await disconnect();
      }

      debugPrint('[Bluetooth] Connecting to $deviceAddress...');
      _connection = await BluetoothConnection.toAddress(deviceAddress);
      
      _isConnected = true;
      _connectedDevice = _pairedDevices.firstWhere(
        (d) => d.address == deviceAddress,
        orElse: () => BluetoothPrinterDevice(
          name: 'Unknown Device',
          address: deviceAddress,
        ),
      );

      debugPrint('[Bluetooth] ✓ Connected to ${_connectedDevice?.name}');
      _statusController.add(true);

      // Listen for connection closed
      _connection?.input?.listen((_) {}).onDone(() {
        disconnect();
      });

      return true;
    } catch (e) {
      debugPrint('[Bluetooth] Connection error: $e');
      _isConnected = false;
      _statusController.add(false);
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        await _connection?.close();
        _connection = null;
      }
      _isConnected = false;
      _connectedDevice = null;
      debugPrint('[Bluetooth] Disconnected');
      _statusController.add(false);
    } catch (e) {
      debugPrint('[Bluetooth] Disconnect error: $e');
    }
  }

  /// Send data to connected device
  Future<bool> sendData(List<int> data) async {
    try {
      if (!isSupported || !_isConnected || _connection == null) {
        debugPrint('[Bluetooth] Not connected');
        return false;
      }

      final uint8data = Uint8List.fromList(data);
      _connection!.output.add(uint8data);
      await _connection!.output.allSent;
      debugPrint('[Bluetooth] Data sent: ${data.length} bytes');
      return true;
    } catch (e) {
      debugPrint('[Bluetooth] Send error: $e');
      return false;
    }
  }

  /// Enable Bluetooth
  Future<void> enableBluetooth() async {
    if (!isSupported) {
      debugPrint('[Bluetooth] Bluetooth printing is not supported on this platform');
      return;
    }

    try {
      await _bluetooth.requestEnable();
      debugPrint('[Bluetooth] ✓ Bluetooth enabled');
    } catch (e) {
      debugPrint('[Bluetooth] Enable error: $e');
    }
  }

  /// Cleanup
  void dispose() {
    _reconnectTimer?.cancel();
    _statusController.close();
    _devicesController.close();
    _discoverySubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    disconnect();
  }
}
