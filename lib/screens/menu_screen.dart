import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pos_provider.dart';
import '../services/thermal_printer_service.dart';
import '../services/bluetooth_service.dart';
import '../services/cache_service.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/skeleton_widget.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _allTxns = [];
  List<Map<String, dynamic>> _logs = [];
  bool _loadingSummary = false;
  bool _loadingTxns = false;
  bool _loadingLogs = false;
  bool _loadingClosingReport = false;
  final _dateFormat = DateFormat('dd/MM/yy');
  final _timeFormat = DateFormat('HH:mm');
  final _currencyFormat = NumberFormat.decimalPattern('id');
  DateTime _closingDate = DateTime.now();
  List<Map<String, dynamic>> _productsSold = [];
  List<Map<String, dynamic>> _payments = [];
  Map<String, int> _txCounts = {'completed': 0, 'held': 0};
  int _modalAwal = 0;
  bool _closingReportLoaded = false;

  Future<void> _loadClosingReport() async {
    final supabase = ref.read(supabaseServiceProvider);
    setState(() => _loadingClosingReport = true);
    try {
      final results = await Future.wait([
        supabase.getProductsSold(_closingDate),
        supabase.getPaymentBreakdown(_closingDate),
        supabase.getTransactionCounts(_closingDate),
      ]);
      if (mounted) {
        setState(() {
          _productsSold = results[0] as List<Map<String, dynamic>>;
          _payments = results[1] as List<Map<String, dynamic>>;
          _txCounts = results[2] as Map<String, int>;
          _closingReportLoaded = true;
          _loadingClosingReport = false;
        });
      }
    } catch (e) {
      debugPrint('[Menu] Closing report error: $e');
      if (mounted) setState(() => _loadingClosingReport = false);
    }
  }

  Future<void> _printClosingReport() async {
    if (!_closingReportLoaded) return;
    final bluetooth = BluetoothService();
    if (!bluetooth.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer Bluetooth tidak terhubung')),
      );
      return;
    }
    final printer = ThermalPrinterService();
    final user = ref.read(posProvider).currentUser;
    final totalPenerimaan = _payments.fold<int>(0, (sum, p) => sum + (p['amount'] as int? ?? 0));
    final success = await printer.printClosingReport(
      branchName: user?.branchName ?? '',
      cashierName: user?.name ?? '',
      waktuBuka: DateTime(_closingDate.year, _closingDate.month, _closingDate.day, 7, 0),
      waktuTutup: DateTime(_closingDate.year, _closingDate.month, _closingDate.day, 21, 0),
      modalAwal: _modalAwal,
      productsSold: _productsSold,
      payments: _payments,
      totalPenerimaan: totalPenerimaan,
      totalTransaksiSelesai: _txCounts['completed'] ?? 0,
      totalTransaksiHold: _txCounts['held'] ?? 0,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Laporan berhasil dicetak' : 'Cetak laporan gagal'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closingDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _closingDate) {
      setState(() => _closingDate = picked);
      _loadClosingReport();
    }
  }

  Future<void> _printDailySummary() async {
    final bluetooth = BluetoothService();
    if (!bluetooth.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer Bluetooth tidak terhubung')),
      );
      return;
    }

    final printer = ThermalPrinterService();
    final user = ref.read(posProvider).currentUser;

    final productsSold = _productsSold;
    final payments = _payments;
    final txCounts = _txCounts;
    final totalPenerimaan = payments.fold<int>(0, (s, p) => s + (p['amount'] as int? ?? 0));

    final success = await printer.printClosingReport(
      branchName: user?.branchName ?? '',
      cashierName: user?.name ?? '',
      waktuBuka: DateTime(_closingDate.year, _closingDate.month, _closingDate.day, 7, 0),
      waktuTutup: DateTime.now(),
      modalAwal: _modalAwal,
      productsSold: productsSold,
      payments: payments,
      totalPenerimaan: totalPenerimaan,
      totalTransaksiSelesai: txCounts['completed'] ?? 0,
      totalTransaksiHold: txCounts['held'] ?? 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Ringkasan berhasil dicetak' : 'Cetak ringkasan gagal'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final supabase = ref.read(supabaseServiceProvider);
    final user = ref.read(posProvider).currentUser;
    final isAdmin = user?.isAdmin ?? false;

    setState(() {
      _loadingSummary = true;
      _loadingTxns = true;
      _loadingLogs = isAdmin; // Only load logs for admin
    });

    final futures = [
      supabase.fetchDailySummary(),
      supabase.fetchAllTransactions(),
    ];
    if (isAdmin) {
      futures.add(supabase.fetchActivityLogs());
    }

    final results = await Future.wait(futures);

    if (mounted) {
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _allTxns = results[1] as List<Map<String, dynamic>>;
        if (isAdmin && results.length > 2) {
          _logs = results[2] as List<Map<String, dynamic>>;
        }
        _loadingSummary = false;
        _loadingTxns = false;
        _loadingLogs = false;
      });
    }
    
    // Sync data to local SQLite (fire and forget)
    _cacheAllToLocal();
  }

  Future<void> _cacheAllToLocal() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final cache = CacheService(supabase);
      final user = ref.read(posProvider).currentUser;
      await cache.syncAllToLocal(cashierId: user?.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final posState = ref.watch(posProvider);
    final user = posState.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    if (user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Silakan login terlebih dahulu', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spaceNormal,
          ResponsiveUtils.spaceNormal,
          ResponsiveUtils.spaceNormal,
          ResponsiveUtils.spaceLarge * 1.5,
        ),
        children: [
          _buildHeader('Ringkasan Harian', Icons.bar_chart, AppColors.primaryGreen),
          if (_loadingSummary) const SkeletonBox(height: 140, borderRadius: 12)
          else _buildSummaryTable(),
          SizedBox(height: ResponsiveUtils.spaceNormal),
          _buildHeader('Laporan Tutup Kasir', Icons.receipt, AppColors.orange),
          _buildClosingReportSection(),
          SizedBox(height: ResponsiveUtils.spaceNormal),
          _buildHeader('Transaksi', Icons.receipt_long, AppColors.darkBlue),
          if (_loadingTxns) const SkeletonBox(height: 200, borderRadius: 12)
          else _buildTransactionList(),
          // Aktivitas Harian — hanya untuk admin
          if (isAdmin) ...[
            SizedBox(height: ResponsiveUtils.spaceNormal),
            _buildHeader('Aktivitas Harian', Icons.history, AppColors.orange),
            if (_loadingLogs) const SkeletonBox(height: 200, borderRadius: 12)
            else _buildActivityLogList(),
          ],
        ],
      ),
    );
  }

  Widget _buildClosingReportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker + Modal Awal row
            Row(
              children: [
                const Text('Tanggal: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateFormat.format(_closingDate), style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                const Text('Modal Awal: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(
                  width: 90,
                  height: 20,
                  child: TextField(
                    onChanged: (v) {
                      final parsed = int.tryParse(v.replaceAll('.', ''));
                      if (parsed != null) _modalAwal = parsed;
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const Spacer(),
                if (_closingReportLoaded)
                  ElevatedButton.icon(
                    onPressed: _printClosingReport,
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const Divider(height: 8),
            // Loading
            if (_loadingClosingReport)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            // Products sold list
            else if (_closingReportLoaded) ...[
              const Text('Produk Terjual:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              ..._productsSold.take(15).map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Expanded(child: Text(p['name'] as String? ?? '', style: const TextStyle(fontSize: 11))),
                    Text('x${p['qty']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text('Rp ${_currencyFormat.format(p['total'] as int? ?? 0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(height: 8),
              // Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Penerimaan:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Rp ${_currencyFormat.format(_payments.fold<int>(0, (s, p) => s + (p['amount'] as int? ?? 0)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaksi Selesai: ${_txCounts['completed'] ?? 0}',
                    style: const TextStyle(fontSize: 11)),
                  Text('Hold: ${_txCounts['held'] ?? 0}',
                    style: const TextStyle(fontSize: 11)),
                ],
              ),
              // Payment breakdown
              const SizedBox(height: 8),
              const Text('Penerimaan per Metode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ..._payments.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Expanded(child: Text(p['method'] as String? ?? '', style: const TextStyle(fontSize: 11))),
                    Text('Rp ${_currencyFormat.format(p['amount'] as int? ?? 0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )),
            ]
            // Not loaded yet
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _loadClosingReport,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Muat Data', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spaceSmall),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    final revenue = _summary['total_revenue'] as int? ?? 0;
    final txCount = _summary['total_transaksi'] as int? ?? 0;
    final refund = _summary['total_refund'] as int? ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _summaryRow('Total Transaksi', '$txCount transaksi', 'Rp ${_currencyFormat.format(revenue)}', Icons.receipt, AppColors.primaryGreen),
            const Divider(height: 16),
            _summaryRow('Cash', '${_summary['cash'] ?? 0} transaksi', 'Rp ${_currencyFormat.format(_summary['cash'] as int? ?? 0)}', Icons.money, Colors.green),
            const Divider(height: 16),
            _summaryRow('Debit', '', 'Rp ${_currencyFormat.format(_summary['debit'] as int? ?? 0)}', Icons.credit_card, Colors.blue),
            const Divider(height: 16),
            _summaryRow('QRIS', '', 'Rp ${_currencyFormat.format(_summary['qris'] as int? ?? 0)}', Icons.qr_code, Colors.purple),
            const Divider(height: 16),
            _summaryRow('E-Wallet', '', 'Rp ${_currencyFormat.format(_summary['e_wallet'] as int? ?? 0)}', Icons.wallet, Colors.teal),
            if (refund > 0) ...[
              const Divider(height: 16),
              _summaryRow('Refund', '$refund transaksi', '-Rp ${_currencyFormat.format(refund)}', Icons.replay, Colors.red),
            ],
            const Divider(height: 16),
            // Print summary button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _printDailySummary,
                icon: const Icon(Icons.print, size: 16, color: Colors.white),
                label: const Text('Print Ringkasan', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String subtitle, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkBlue)),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_allTxns.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey[500]))),
        ),
      );
    }
    return Column(
      children: _allTxns.take(20).map((t) => _buildTransactionCard(t)).toList(),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    final status = t['status'] as String? ?? '';
    final isRefunded = status == 'refunded';
    final method = t['payment_method'] as String? ?? '';
    final methodLabel = method == 'e_wallet' ? 'E-Wallet' : method.substring(0, 1).toUpperCase() + method.substring(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isRefunded ? Colors.red.withValues(alpha: 0.04) : null,
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isRefunded ? Colors.red.withValues(alpha: 0.12) : AppColors.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(isRefunded ? Icons.replay : Icons.receipt, size: 18,
            color: isRefunded ? Colors.red : AppColors.primaryGreen),
        ),
        title: Text('Order #${t['order_no']} — ${t['customer_name'] ?? 'Tanpa nama'}',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            decoration: isRefunded ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${_dateFormat.format(DateTime.parse(t['created_at'] as String))} — $methodLabel',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
        trailing: Text('Rp ${_currencyFormat.format(t['total_amount'] ?? 0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13,
            color: isRefunded ? Colors.red : AppColors.darkBlue,
          ),
        ),
        onTap: () => _showTransactionDetail(t),
      ),
    );
  }

  void _showTransactionDetail(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${t['order_no']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
            const Divider(),
            _detailRow('Pelanggan', t['customer_name'] as String? ?? '-'),
            _detailRow('Kasir', t['cashier_name'] as String? ?? '-'),
            _detailRow('Metode', t['payment_method'] as String? ?? '-'),
            _detailRow('Status', t['status'] as String? ?? '-'),
            _detailRow('Total', 'Rp ${_currencyFormat.format(t['total_amount'] ?? 0)}'),
            _detailRow('Dibayar', 'Rp ${_currencyFormat.format(t['amount_paid'] ?? 0)}'),
            _detailRow('Kembalian', 'Rp ${_currencyFormat.format(t['change_amount'] ?? 0)}'),
            _detailRow('Waktu', _dateFormat.format(DateTime.parse(t['created_at'] as String))),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActivityLogList() {
    if (_logs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey[500]))),
        ),
      );
    }
    return Column(
      children: _logs.take(30).map((log) {
        final action = log['action'] as String? ?? '';
        final userName = log['user_name'] as String? ?? 'Unknown';
        final createdAt = DateTime.parse(log['created_at'] as String);
        IconData icon;
        Color color;
        String label;

        if (action == 'transaksi_baru') {
          icon = Icons.shopping_cart_checkout; color = AppColors.primaryGreen; label = 'Transaksi Baru';
        } else if (action == 'refund_baru') {
          icon = Icons.replay; color = Colors.red; label = 'Refund';
        } else {
          icon = Icons.info_outline; color = AppColors.darkBlue; label = action;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            dense: true,
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('$userName — ${_timeFormat.format(createdAt)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
            trailing: Text(_dateFormat.format(createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ),
        );
      }).toList(),
    );
  }
}
