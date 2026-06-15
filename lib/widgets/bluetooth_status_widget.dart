import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bluetooth_provider.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import 'bluetooth_connection_dialog.dart';

class BluetoothStatusWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const BluetoothStatusWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(bluetoothStatusProvider);

    return statusAsync.when(
      data: (isConnected) {
        return GestureDetector(
          onTap: () {
            onTap?.call();
            showDialog(
              context: context,
              builder: (context) => const BluetoothConnectionDialog(),
            );
          },
          child: Tooltip(
            message: isConnected ? 'Printer connected. Tap to disconnect/reconnect' : 'Tap to connect printer',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spaceSmall,
                vertical: ResponsiveUtils.spaceXSmall,
              ),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(
                  color: isConnected ? AppColors.primaryGreen : Colors.red,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.print,
                    color: isConnected ? AppColors.primaryGreen : Colors.red,
                    size: ResponsiveUtils.iconSmall,
                  ),
                  SizedBox(width: ResponsiveUtils.spaceXSmall),
                  Text(
                    isConnected ? 'Printer' : 'No Printer',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSmall,
                      color: isConnected ? AppColors.primaryGreen : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spaceSmall),
        child: SizedBox(
          width: ResponsiveUtils.iconSmall,
          height: ResponsiveUtils.iconSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
      error: (error, stack) => Tooltip(
        message: 'Bluetooth error',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spaceSmall,
            vertical: ResponsiveUtils.spaceXSmall,
          ),
          child: Icon(
            Icons.bluetooth_disabled,
            color: Colors.orange,
            size: ResponsiveUtils.iconSmall,
          ),
        ),
      ),
    );
  }
}
