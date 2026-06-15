import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bluetooth_service.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/responsive_utils.dart';

class BluetoothConnectionDialog extends ConsumerStatefulWidget {
  const BluetoothConnectionDialog({super.key});

  @override
  ConsumerState<BluetoothConnectionDialog> createState() =>
      _BluetoothConnectionDialogState();
}

class _BluetoothConnectionDialogState
    extends ConsumerState<BluetoothConnectionDialog> {
  BluetoothPrinterDevice? _selectedDevice;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bluetooth = ref.read(bluetoothServiceProvider);
      bluetooth.getPairedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final devicesAsync = ref.watch(bluetoothDevicesProvider);
    final bluetooth = ref.watch(bluetoothServiceProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.radiusMedium),
      ),
      child: Padding(
        padding: ResponsiveUtils.paddingNormal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Menjaga teks kiri agar rapi
          children: [
            // Title
            Center( // Membuat judul tetap di tengah jika diinginkan
              child: Text(
                'Connect Thermal Printer',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spaceNormal),

            // Status indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bluetooth.isEnabled ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spaceSmall),
                Text(
                  bluetooth.isEnabled ? 'Bluetooth: ON' : 'Bluetooth: OFF',
                  style: TextStyle(fontSize: ResponsiveUtils.fontNormal),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spaceSmall),
            const Divider(),
            SizedBox(height: ResponsiveUtils.spaceSmall),

            // Devices list header
            Text(
              'Available Devices:',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontNormal,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spaceSmall),

            // Perubahan Utama: Dibungkus dengan Flexible agar list device bisa di-scroll saat penuh
            Flexible(
              child: devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spaceNormal,
                      ),
                      child: Center(
                        child: Text(
                          'No paired Bluetooth devices found',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSmall,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // Menggunakan SingleChildScrollView + Column (atau ListView biasa) 
                  // di dalam Flexible agar terhindar dari benturan ukuran (constraint)
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return Card(
                        margin: EdgeInsets.only(
                          bottom: ResponsiveUtils.spaceXSmall,
                        ),
                        elevation: 1,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                            });
                          },
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.radiusSmall,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.spaceNormal,
                              vertical: ResponsiveUtils.spaceSmall,
                            ),
                            child: Row(
                              children: [
                                Radio<BluetoothPrinterDevice>(
                                  value: device,
                                  groupValue: _selectedDevice,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDevice = value;
                                    });
                                  },
                                ),
                                SizedBox(width: ResponsiveUtils.spaceSmall),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.fontNormal,
                                        ),
                                      ),
                                      SizedBox(
                                        height: ResponsiveUtils.spaceXSmall,
                                      ),
                                      Text(
                                        device.address,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.fontSmall,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spaceNormal,
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spaceNormal,
                  ),
                  child: Center(
                    child: Text(
                      'Error: $error',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSmall,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.spaceNormal),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: ResponsiveUtils.fontNormal),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spaceSmall),
                ElevatedButton(
                  onPressed: _isConnecting || _selectedDevice == null
                      ? null
                      : _handleConnect,
                  child: _isConnecting
                      ? SizedBox(
                          height: ResponsiveUtils.iconNormal,
                          width: ResponsiveUtils.iconNormal,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Connect',
                          style: TextStyle(fontSize: ResponsiveUtils.fontNormal),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConnect() async {
    if (_selectedDevice == null) return;

    setState(() => _isConnecting = true);

    final bluetooth = ref.read(bluetoothServiceProvider);
    final success = await bluetooth.connect(_selectedDevice!.address);

    if (mounted) {
      setState(() => _isConnecting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected to ${_selectedDevice!.name}',
              style: TextStyle(fontSize: ResponsiveUtils.fontNormal),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to connect to ${_selectedDevice!.name}',
              style: TextStyle(fontSize: ResponsiveUtils.fontNormal),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}