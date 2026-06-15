import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/bluetooth_status_widget.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/connectivity_banner.dart';
import 'pos_screen.dart';
import 'history_screen.dart';
import 'menu_screen.dart';

class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveUtils.init(context);
    final posState = ref.watch(posProvider);
    final user = posState.currentUser;
    final today = DateTime.now();
    final todayTrans = posState.transactions.where((t) =>
      t.createdAt.year == today.year &&
      t.createdAt.month == today.month &&
      t.createdAt.day == today.day &&
      t.status.name == 'completed').length;
    final todayRev = posState.transactions.where((t) =>
      t.createdAt.year == today.year &&
      t.createdAt.month == today.month &&
      t.createdAt.day == today.day &&
      t.status.name == 'completed')
      .fold(0, (sum, t) => sum + t.totalAmount);
    final currencyFormat = NumberFormat.decimalPattern('id');

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: Scaffold(
              backgroundColor: AppColors.backgroundLight,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                // Lebih ramping: 60 → 56
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      // Logo / branch badge — dikecilkan sedikit
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'lib/assets/logo-dhbh.png',
                              width: 60,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                            if (user?.branchName != null) ...[
                              const SizedBox(width: 4),
                              Container(width: 1, height: 12,
                                color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 90),
                                child: Text(user!.branchName!,
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Stats badge — compact
                      _buildTransactionBadge(todayTrans, todayRev, currencyFormat),
                      const SizedBox(width: 6),
                      const BluetoothStatusWidget(),
                      const SizedBox(width: 6),
                      const SyncStatusWidget(),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => ref.read(posProvider.notifier).logout(),
                        child: _buildUserProfile(
                          user?.name ?? 'User',
                          user?.role.name ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: const TabBarView(
                children: [POSScreen(), HistoryScreen(), MenuScreen()],
              ),
              // Bottom nav lebih tipis: 58px + margin 8
              bottomNavigationBar: Container(
                height: 58,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  onTap: (index) => ref.read(posProvider.notifier).loadProducts(),
                  indicator: const BoxDecoration(),
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: const Color(0xFF999999),
                  tabs: const [
                    Tab(icon: Icon(Icons.home, size: 22),
                        child: Text('POS', style: TextStyle(fontSize: 10))),
                    Tab(icon: Icon(Icons.receipt_long, size: 22),
                        child: Text('History', style: TextStyle(fontSize: 10))),
                    Tab(icon: Icon(Icons.person, size: 22),
                        child: Text('Menu', style: TextStyle(fontSize: 10))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBadge(int count, int revenue, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xAF00F72D),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt, color: AppColors.gray, size: 12),
          const SizedBox(width: 3),
          Text('$count',
            style: const TextStyle(
              color: AppColors.gray, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.monetization_on, color: AppColors.gray, size: 12),
          const SizedBox(width: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(format.format(revenue),
              style: const TextStyle(
                color: AppColors.gray, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(String name, String role) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.grayProfileBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person, color: AppColors.darkBlue, size: 15),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(role.toUpperCase(),
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.60),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(name,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.70),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.logout, color: AppColors.darkBlue, size: 14),
      ],
    );
  }
}
