import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/backup_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  Map<String, dynamic> _backupInfo = {};
  bool _loadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() => _loadingInfo = true);
    try {
      final info = await ref.read(backupProvider.notifier).getBackupInfo();
      if (mounted) {
        setState(() {
          _backupInfo = info;
          _loadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  Future<void> _startBackup() async {
    final appVersion = '1.0.0+1'; // From pubspec.yaml
    await ref.read(backupProvider.notifier).runBackup(appVersion: appVersion);
    if (mounted) {
      _loadBackupInfo();
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    final backupState = ref.watch(backupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Data'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Backup Info Card ──
            _buildInfoCard(),
            const SizedBox(height: 16),

            // ── Progress Section ──
            if (backupState.isRunning) _buildProgressSection(backupState),

            // ── Error Section ──
            if (backupState.errorMessage != null && !backupState.isRunning)
              _buildErrorSection(backupState.errorMessage!),

            // ── Success Section ──
            if (backupState.isSuccess && backupState.result != null)
              _buildSuccessSection(backupState.result!),

            // ── Backup Button ──
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: backupState.isRunning ? null : _startBackup,
                icon: Icon(
                  backupState.isRunning ? Icons.hourglass_top : Icons.backup,
                  color: Colors.white,
                ),
                label: Text(
                  backupState.isRunning ? 'Memproses...' : 'Mulai Backup',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final hasBackup = _backupInfo['hasBackup'] == true;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Informasi Backup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_loadingInfo)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _infoRow('Terakhir Backup',
                  hasBackup ? _formatDateTime(_backupInfo['lastBackupTime'] as String?) : 'Belum pernah'),
              const SizedBox(height: 8),
              _infoRow('Ukuran Backup',
                  hasBackup ? _formatSize(_backupInfo['backupSize'] as int? ?? 0) : '-'),
              const SizedBox(height: 8),
              _infoRow('Versi Database', '${_backupInfo['databaseVersion'] ?? 1}'),
              const SizedBox(height: 8),
              _infoRow('Total Produk', '${_backupInfo['totalProducts'] ?? 0}'),
              const SizedBox(height: 8),
              _infoRow('Total Pelanggan', '${_backupInfo['totalCustomers'] ?? 0}'),
              const SizedBox(height: 8),
              _infoRow('Total Transaksi', '${_backupInfo['totalTransactions'] ?? 0}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BackupState state) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.currentMessage ?? 'Memproses...',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup Gagal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: ${_cleanError(error)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _startBackup,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessSection(Map<String, int> result) {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Backup Berhasil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _resultRow('Produk', result['products'] ?? 0),
            _resultRow('Pelanggan', result['customers'] ?? 0),
            _resultRow('Transaksi', result['transactions'] ?? 0),
            _resultRow('Kategori', result['categories'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Text('$label : ', style: const TextStyle(fontSize: 12, color: Colors.green)),
          Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  String _cleanError(String error) {
    if (error.contains('FormatException')) return 'Gagal memproses data';
    if (error.contains('TimeoutException') || error.contains('timeout')) return 'Koneksi timeout';
    if (error.contains('NetworkError') || error.contains('SocketException')) return 'Gangguan jaringan';
    if (error.contains('Internet') || error.contains('koneksi')) return 'Periksa koneksi internet';
    return error;
  }
}
