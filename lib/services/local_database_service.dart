import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  Database? _db;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dhbh_offline.db');

    debugPrint('[LocalDB] Initializing database at: $path');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _initialized = true;
    debugPrint('[LocalDB] ✓ Database initialized');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[LocalDB] Creating database schema v$version');

    // cached_products — mirror products table
    await db.execute('''
      CREATE TABLE cached_products (
        id INTEGER PRIMARY KEY,
        item_no INTEGER,
        category_id INTEGER,
        category TEXT,
        name TEXT NOT NULL,
        description TEXT,
        price_clinic INTEGER NOT NULL,
        price_home_visit INTEGER,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // offline_accounts — mirror user_profiles + login fields
    await db.execute('''
      CREATE TABLE offline_accounts (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        full_name TEXT NOT NULL,
        role_id INTEGER NOT NULL,
        branch_id INTEGER,
        fingerprints TEXT,
        is_active INTEGER DEFAULT 1,
        email TEXT,
        password_hash TEXT,
        branch_name TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // offline_transactions — mirror transactions
    await db.execute('''
      CREATE TABLE offline_transactions (
        id TEXT PRIMARY KEY,
        order_no INTEGER,
        branch_id INTEGER,
        cashier_id TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        total_amount INTEGER NOT NULL,
        amount_paid INTEGER NOT NULL,
        change_amount INTEGER,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        print_status TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // cached_held_orders — mirror held_orders
    await db.execute('''
      CREATE TABLE cached_held_orders (
        id INTEGER PRIMARY KEY,
        branch_id INTEGER,
        cashier_id TEXT,
        items TEXT NOT NULL,
        notes TEXT,
        customer_name TEXT,
        hold_order_status TEXT DEFAULT 'active',
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // pending_sync — queue for offline actions
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // cashier_shifts — for closing report (mirror Supabase)
    await db.execute('''
      CREATE TABLE cashier_shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id TEXT NOT NULL,
        branch_id INTEGER,
        modal_awal INTEGER DEFAULT 0,
        waktu_buka TEXT,
        waktu_tutup TEXT,
        tanggal TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    debugPrint('[LocalDB] ✓ All tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[LocalDB] Migration: v$oldVersion → v$newVersion');
    // Future migrations go here
  }

  // ─── GENERIC CRUD ────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data,
      {required String where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data,
        where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table,
      {required String where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs,
      String? orderBy, int? limit}) async {
    final db = await database;
    return await db.query(table,
        where: where, whereArgs: whereArgs,
        orderBy: orderBy, limit: limit);
  }

  Future<Map<String, dynamic>?> querySingle(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final results = await db.query(table,
        where: where, whereArgs: whereArgs, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  // ─── PRODUCTS ─────────────────────────────────────────────────────

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cached_products');
      for (final product in products) {
        await txn.insert('cached_products', {
          'id': product['id'],
          'item_no': product['item_no'],
          'category_id': product['category_id'],
          'category': product['category'] ?? '',
          'name': product['name'],
          'description': product['description'],
          'price_clinic': product['price_clinic'],
          'price_home_visit': product['price_home_visit'],
          'image_url': product['image_url'],
          'is_active': product['is_active'] ?? 1,
          'created_at': product['created_at'],
          'updated_at': product['updated_at'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    debugPrint('[LocalDB] Cached ${products.length} products');
  }

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    return await query('cached_products', orderBy: 'item_no ASC');
  }

  // ─── ACCOUNTS ─────────────────────────────────────────────────────

  Future<void> saveAccount(Map<String, dynamic> account) async {
    await insert('offline_accounts', account);
    debugPrint('[LocalDB] Account saved: ${account['username']}');
  }

  Future<Map<String, dynamic>?> getAccountByUsername(String username) async {
    return await querySingle('offline_accounts',
        where: 'username = ?', whereArgs: [username]);
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    return await query('offline_accounts', orderBy: 'full_name ASC');
  }

  Future<void> deleteAccount(String id) async {
    await delete('offline_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────────────

  Future<void> saveOfflineTransaction(Map<String, dynamic> transaction) async {
    await insert('offline_transactions', transaction);
    debugPrint('[LocalDB] Offline transaction saved: ${transaction['id']}');
  }

  Future<List<Map<String, dynamic>>> getAllCachedTransactions() async {
    return await query('offline_transactions',
        orderBy: 'created_at DESC', limit: 100);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    return await query('offline_transactions',
        where: 'synced = 0', orderBy: 'created_at ASC');
  }

  Future<void> markTransactionSynced(String id) async {
    await update('offline_transactions',
        {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── HELD ORDERS ──────────────────────────────────────────────────

  Future<void> saveHeldOrder(Map<String, dynamic> order) async {
    await insert('cached_held_orders', order);
    debugPrint('[LocalDB] Held order saved locally');
  }

  Future<List<Map<String, dynamic>>> getAllCachedHeldOrders() async {
    return await query('cached_held_orders',
        where: 'hold_order_status = ?', whereArgs: ['active'],
        orderBy: 'created_at DESC');
  }

  Future<void> completeLocalHeldOrder(int id) async {
    await update('cached_held_orders',
        {'hold_order_status': 'completed', 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLocalHeldOrder(int id) async {
    await delete('cached_held_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateHeldOrderStatus(int id, String status) async {
    await update('cached_held_orders',
        {'hold_order_status': status, 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHeldOrder(int id) async {
    await delete('cached_held_orders', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CASHIER SHIFTS ────────────────────────────────────────────────

  Future<void> saveShift(Map<String, dynamic> shift) async {
    await insert('cashier_shifts', shift);
    debugPrint('[LocalDB] Shift saved locally');
  }

  Future<List<Map<String, dynamic>>> getShiftsByDate(String tanggal) async {
    return await query('cashier_shifts',
        where: 'tanggal = ?', whereArgs: [tanggal],
        orderBy: 'created_at DESC');
  }

  Future<int> getModalAwal(String tanggal, String cashierId) async {
    final result = await querySingle('cashier_shifts',
        where: 'tanggal = ? AND cashier_id = ?',
        whereArgs: [tanggal, cashierId]);
    return (result?['modal_awal'] as int?) ?? 0;
  }

  Future<void> updateShiftWaktuTutup(int id, String waktuTutup) async {
    await update('cashier_shifts',
        {'waktu_tutup': waktuTutup, 'synced': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── PENDING SYNC QUEUE ───────────────────────────────────────────

  Future<void> addToSyncQueue({
    required String action,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await insert('pending_sync', {
      'action': action,
      'table_name': tableName,
      'record_id': recordId,
      'payload': payload.toString(), // Simple string serialization
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('[LocalDB] Added to sync queue: $action ($tableName)');
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    return await query('pending_sync',
        orderBy: 'created_at ASC');
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_sync');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> removeSyncItem(int id) async {
    await delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_sync SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> updateSyncError(int id, String error) async {
    await update('pending_sync',
        {'last_error': error},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── DISPOSE ──────────────────────────────────────────────────────

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _initialized = false;
    }
  }
}
