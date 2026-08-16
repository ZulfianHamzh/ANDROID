import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'backup_repository.dart';

/// Backup Service — orchestrates the manual backup workflow.
/// Fetches latest data from Supabase and stores it in SQLite backup.
class BackupService {
  final SupabaseService _supabase;
  final BackupRepository _backupRepo;

  BackupService(this._supabase) : _backupRepo = BackupRepository();

  Future<void> _log(String message) async {
    debugPrint('[Backup] $message');
  }

  /// Run full backup sequence.
  /// Calls [onProgress] with status messages for UI display.
  /// Returns a map with backup counts on success, throws on failure.
  Future<Map<String, int>> runBackup({
    required String appVersion,
    Function(String message)? onProgress,
  }) async {
    _log('══════════ Backup Started ══════════');
    onProgress?.call('Memulai Backup...');

    int productCount = 0;
    int customerCount = 0;
    int transactionCount = 0;
    int categoryCount = 0;

    // ── Step 1: Backup Products ──────────────────────────────────
    onProgress?.call('Mendownload Produk...');
    _log('Downloading Products...');
    try {
      final products = await _supabase.fetchProducts();
      _log('${products.length} Products Downloaded');

      onProgress?.call('Menyimpan Produk...');
      final rows = products.map((p) => {
        'id': p.id,
        'item_no': p.itemNo,
        'name': p.name,
        'category': p.category,
        'price_clinic': p.priceClinic,
        'price_home_visit': p.priceHomeVisit,
        'image_url': p.imageUrl,
        'is_active': p.isActive ? 1 : 0,
        'branch_prices': p.branchPrices.map((bp) =>
          '${bp.id},${bp.productId},${bp.branchId},${bp.priceClinic ?? ''},${bp.priceHomeVisit ?? ''}'
        ).join('|'),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      productCount = await _backupRepo.saveProducts(rows);
      _log('$productCount Products Saved');
    } catch (e) {
      _log('Products backup FAILED: $e');
      onProgress?.call('Gagal backup produk: $e');
      rethrow;
    }

    // ── Step 2: Backup Customers ─────────────────────────────────
    onProgress?.call('Mendownload Pelanggan...');
    _log('Downloading Customers...');
    try {
      final customers = await _supabase.fetchCustomers();
      _log('${customers.length} Customers Downloaded');

      onProgress?.call('Menyimpan Pelanggan...');
      final rows = customers.map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'address': c.address,
        'total_visits': c.totalVisits,
        'total_spent': c.totalSpent,
        'created_at': c.createdAt?.toIso8601String(),
        'updated_at': c.updatedAt?.toIso8601String(),
      }).toList();
      customerCount = await _backupRepo.saveCustomers(rows);
      _log('$customerCount Customers Saved');
    } catch (e) {
      _log('Customers backup FAILED: $e');
      onProgress?.call('Gagal backup pelanggan: $e');
      rethrow;
    }

    // ── Step 3: Backup Transactions ──────────────────────────────
    onProgress?.call('Mendownload Transaksi...');
    _log('Downloading Transactions...');
    try {
      final transactions = await _supabase.fetchTransactions();
      _log('${transactions.length} Transactions Downloaded');

      onProgress?.call('Menyimpan Transaksi...');
      final rows = transactions.map((t) => {
        'id': t.id is int ? t.id : int.tryParse(t.id) ?? 0,
        'order_no': t.orderNo,
        'cashier_id': t.cashierId,
        'customer_name': t.customerName,
        'total_amount': t.totalAmount,
        'amount_paid': t.amountPaid,
        'change_amount': t.change,
        'payment_method': t.paymentMethod.name,
        'status': t.status.name,
        'print_status': t.printStatus.name,
        'created_at': t.createdAt.toIso8601String(),
      }).toList();
      transactionCount = await _backupRepo.saveTransactions(rows);
      _log('$transactionCount Transactions Saved');
    } catch (e) {
      _log('Transactions backup FAILED: $e');
      onProgress?.call('Gagal backup transaksi: $e');
      rethrow;
    }

    // ── Step 4: Backup Categories ────────────────────────────────
    onProgress?.call('Mendownload Kategori...');
    _log('Downloading Categories...');
    try {
      final categories = await _supabase.fetchCategories();
      _log('${categories.length} Categories Downloaded');

      onProgress?.call('Menyimpan Kategori...');
      final rows = categories.map((c) => {
        'id': c['id'],
        'name': c['name'],
      }).toList();
      categoryCount = await _backupRepo.saveCategories(rows);
      _log('$categoryCount Categories Saved');
    } catch (e) {
      _log('Categories backup FAILED (non-critical): $e');
      // Non-critical — continue
    }

    // ── Step 5: Save Backup Info ──────────────────────────────────
    onProgress?.call('Menyimpan Informasi Backup...');
    await _backupRepo.saveBackupInfo(
      productCount: productCount,
      customerCount: customerCount,
      transactionCount: transactionCount,
      categoryCount: categoryCount,
      appVersion: appVersion,
    );

    _log('══════════ Backup Finished ══════════');
    onProgress?.call('Backup Selesai!');

    return {
      'products': productCount,
      'customers': customerCount,
      'transactions': transactionCount,
      'categories': categoryCount,
    };
  }

  /// Get backup display info.
  Future<Map<String, dynamic>> getBackupInfo() async {
    return await _backupRepo.getBackupDisplayInfo();
  }
}
