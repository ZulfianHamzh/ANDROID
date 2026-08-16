import 'package:flutter/foundation.dart';
import 'backup_database.dart';

/// Backup Repository — handles all SQLite backup read/write operations.
/// This is the ONLY class that interacts with BackupDatabase.
class BackupRepository {
  final BackupDatabase _db;

  BackupRepository() : _db = BackupDatabase();

  Future<void> _log(String message) async {
    debugPrint('[BackupRepo] $message');
  }

  // ─── PRODUCTS ─────────────────────────────────────────────────

  Future<int> saveProducts(List<Map<String, dynamic>> products) async {
    await _log('Saving ${products.length} products to backup...');
    await _db.deleteAll('products');
    final count = await _db.insertBatch('products', products);
    await _log('✓ $count products saved to backup');
    return count;
  }

  Future<int> getProductCount() async {
    return await _db.getRowCount('products');
  }

  // ─── CUSTOMERS ────────────────────────────────────────────────

  Future<int> saveCustomers(List<Map<String, dynamic>> customers) async {
    await _log('Saving ${customers.length} customers to backup...');
    await _db.deleteAll('customers');
    final count = await _db.insertBatch('customers', customers);
    await _log('✓ $count customers saved to backup');
    return count;
  }

  Future<int> getCustomerCount() async {
    return await _db.getRowCount('customers');
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────

  Future<int> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await _log('Saving ${transactions.length} transactions to backup...');
    await _db.deleteAll('transactions');
    final count = await _db.insertBatch('transactions', transactions);
    await _log('✓ $count transactions saved to backup');
    return count;
  }

  Future<int> getTransactionCount() async {
    return await _db.getRowCount('transactions');
  }

  // ─── CATEGORIES ───────────────────────────────────────────────

  Future<int> saveCategories(List<Map<String, dynamic>> categories) async {
    await _log('Saving ${categories.length} categories to backup...');
    await _db.deleteAll('categories');
    final count = await _db.insertBatch('categories', categories);
    await _log('✓ $count categories saved to backup');
    return count;
  }

  Future<int> getCategoryCount() async {
    return await _db.getRowCount('categories');
  }

  // ─── BACKUP INFO ──────────────────────────────────────────────

  Future<void> saveBackupInfo({
    required int productCount,
    required int customerCount,
    required int transactionCount,
    required int categoryCount,
    required String appVersion,
  }) async {
    final now = DateTime.now();
    final size = await _db.getDatabaseSize();
    await _db.saveBackupInfo({
      'last_backup_time': now.toIso8601String(),
      'database_version': 1,
      'app_version': appVersion,
      'backup_size_bytes': size,
      'total_products': productCount,
      'total_customers': customerCount,
      'total_transactions': transactionCount,
      'total_categories': categoryCount,
      'created_at': now.toIso8601String(),
    });
    await _log('✓ Backup info saved');
  }

  Future<Map<String, dynamic>?> getBackupInfo() async {
    return await _db.getBackupInfo();
  }

  /// Get formatted backup info string for display.
  Future<Map<String, dynamic>> getBackupDisplayInfo() async {
    final info = await _db.getBackupInfo();
    if (info == null) {
      return {
        'hasBackup': false,
        'lastBackupTime': null,
        'backupSize': 0,
        'totalProducts': 0,
        'totalCustomers': 0,
        'totalTransactions': 0,
        'totalCategories': 0,
        'databaseVersion': 1,
      };
    }
    return {
      'hasBackup': true,
      'lastBackupTime': info['last_backup_time'] as String?,
      'backupSize': info['backup_size_bytes'] as int? ?? 0,
      'totalProducts': info['total_products'] as int? ?? 0,
      'totalCustomers': info['total_customers'] as int? ?? 0,
      'totalTransactions': info['total_transactions'] as int? ?? 0,
      'totalCategories': info['total_categories'] as int? ?? 0,
      'databaseVersion': info['database_version'] as int? ?? 1,
    };
  }
}
