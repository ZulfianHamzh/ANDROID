import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/responsive_utils.dart';

class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncProvider);

    return connectivity.when(
      data: (isOnline) {
        // Online state
        if (isOnline) {
          // If pending sync items, show yellow sync banner
          if (syncState.pendingCount > 0) {
            return _buildBanner(
              backgroundColor: Colors.orange.shade100,
              textColor: Colors.orange.shade900,
              icon: Icons.sync,
              message: '${syncState.pendingCount} data menunggu sync',
              actionLabel: syncState.status == SyncStatus.syncing ? null : 'Sync',
              onAction: syncState.status == SyncStatus.syncing
                  ? null
                  : () => ref.read(syncProvider.notifier).syncAll(),
            );
          }
          // Syncing in progress
          if (syncState.status == SyncStatus.syncing) {
            return _buildBanner(
              backgroundColor: Colors.blue.shade100,
              textColor: Colors.blue.shade900,
              icon: Icons.sync,
              message: 'Menyinkronkan data...',
              showProgress: true,
            );
          }
          // Fully online and synced — show brief green then hide
          return const SizedBox.shrink();
        }

        // Offline state — red persistent banner
        return _buildBanner(
          backgroundColor: Colors.red.shade100,
          textColor: Colors.red.shade900,
          icon: Icons.wifi_off,
          message: 'Anda sedang offline. Data akan sync otomatis.',
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner({
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool showProgress = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spaceNormal,
        vertical: ResponsiveUtils.spaceXSmall,
      ),
      decoration: BoxDecoration(color: backgroundColor),
      child: Row(
        children: [
          if (showProgress)
            SizedBox(
              width: ResponsiveUtils.iconSmall,
              height: ResponsiveUtils.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          else
            Icon(icon, size: ResponsiveUtils.iconSmall, color: textColor),
          SizedBox(width: ResponsiveUtils.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSmall,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSmall,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
