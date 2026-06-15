import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../utils/responsive_utils.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final pendingCount = syncState.pendingCount;

    if (syncState.status == SyncStatus.syncing) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spaceSmall),
        child: SizedBox(
          width: ResponsiveUtils.iconSmall,
          height: ResponsiveUtils.iconSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue,
          ),
        ),
      );
    }

    if (pendingCount > 0) {
      return GestureDetector(
        onTap: () => ref.read(syncProvider.notifier).syncAll(),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spaceSmall,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange, width: 1),
            borderRadius: BorderRadius.circular(ResponsiveUtils.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync, size: 12, color: Colors.orange.shade800),
              SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
