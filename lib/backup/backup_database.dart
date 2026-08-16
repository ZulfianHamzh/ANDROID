import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

/// Backup Database — SQLite used ONLY for manual local backup.
/// NOT used for any POS operations (products, transactions, customers, etc).
/// All operational data reads/writes go directly to Supabase.
class BackupDatabase {
  static final BackupDatabase _instance = BackupDatabase._internal();

  factory BackupDatabase() => _instance;

  BackupDatabase._internal();

  Database? _db;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // On desktop (Windows/Linux), sqflite's native plugin is unavailable.
    // Use the FFI-backed implementation so manual backup works on Windows.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dhbh_backup.db');

    debugPrint('[BackupDB] Initializing database at: $path');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    _initialized = true;
    debugPrint('[BackupDB] ✓ Database initialized');
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[BackupDB] Creating backup schema v$version');

    // products — backup of Supabase products
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY,
        item_no INTEGER,
        name TEXT NOT NULL,
        category TEXT,
        price_clinic INTEGER NOT NULL,
        price_home_visit INTEGER,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        branch_prices TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // customers — backup of Supabase customers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_visits INTEGER DEFAULT 0,
        total_spent INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // transactions — backup of Supabase transactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY,
        order_no INTEGER,
        cashier_id TEXT,
        customer_name TEXT,
        total_amount INTEGER NOT NULL,
        amount_paid INTEGER NOT NULL,
        change_amount INTEGER,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL,
        print_status TEXT,
        created_at TEXT
      )
    ''');

    // categories — backup of Supabase product categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // settings — backup placeholder
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // backup_info — metadata about the last backup
    await db.execute('''
      CREATE TABLE IF NOT EXISTS backup_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_backup_time TEXT,
        database_version INTEGER DEFAULT 1,
        app_version TEXT,
        backup_size_bytes INTEGER DEFAULT 0,
        total_products INTEGER DEFAULT 0,
        total_customers INTEGER DEFAULT 0,
        total_transactions INTEGER DEFAULT 0,
        total_categories INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    debugPrint('[BackupDB] ✓ All backup tables created');
  }

  // ─── GENERIC CRUD ────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertBatch(String table, List<Map<String, dynamic>> rows) async {
    final db = await database;
    int count = 0;
    try {
      await db.transaction((txn) async {
        for (final row in rows) {
          await txn.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        }
      });
    } catch (e) {
      debugPrint('[BackupDB] Batch insert error in $table: $e');
      // Fallback to individual inserts
      for (final row in rows) {
        try {
          await db.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } catch (_) {}
      }
    }
    return count;
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
      {String? where, List<dynamic>? whereArgs,
      String? orderBy}) async {
    final db = await database;
    final results = await db.query(table,
        where: where, whereArgs: whereArgs,
        orderBy: orderBy, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> deleteAll(String table) async {
    final db = await database;
    return await db.delete(table);
  }

  Future<int> getRowCount(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return result.first['count'] as int;
  }

  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'dhbh_backup.db');
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('[BackupDB] Error getting file size: $e');
    }
    return 0;
  }

  // ─── BACKUP INFO ─────────────────────────────────────────────────

  Future<void> saveBackupInfo(Map<String, dynamic> info) async {
    final db = await database;
    // Clear old info, keep only latest
    await db.delete('backup_info');
    await db.insert('backup_info', info);
  }

  Future<Map<String, dynamic>?> getBackupInfo() async {
    return await querySingle('backup_info', orderBy: 'id DESC');
  }
}
