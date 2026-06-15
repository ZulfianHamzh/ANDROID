import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/transaction.dart' as txn;
import '../models/held_order.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/local_database_service.dart';

class CacheService {
  final SupabaseService _supabase;
  final LocalDatabaseService _localDB;

  CacheService(this._supabase) : _localDB = LocalDatabaseService();

  // ─── PRODUCTS ─────────────────────────────────────────────────

  Future<List<Product>> fetchProducts() async {
    try {
      // Try fetching from Supabase first
      final products = await _supabase.fetchProducts();
      
      // Cache to local DB in background
      _cacheProducts(products);
      
      return products;
    } catch (e) {
      debugPrint('[Cache] Supabase products failed: $e — falling back to local');
      
      // Fallback to local cache
      final cached = await _localDB.getCachedProducts();
      if (cached.isEmpty) {
        debugPrint('[Cache] No cached products available');
        rethrow;
      }
      
      debugPrint('[Cache] Returning ${cached.length} cached products');
      return cached.map((row) => Product(
        id: row['id'] as int,
        itemNo: row['item_no'] as int?,
        name: row['name'] as String,
        priceClinic: row['price_clinic'] as int,
        priceHomeVisit: row['price_home_visit'] as int?,
        isActive: (row['is_active'] as int?) == 1,
        category: (row['category'] as String?) ?? '',
        imageUrl: row['image_url'] as String?,
      )).toList();
    }
  }

  Future<void> _cacheProducts(List<Product> products) async {
    try {
      final rows = products.map((p) => {
        'id': p.id,
        'item_no': p.itemNo,
        'category_id': null,
        'category': p.category,
        'name': p.name,
        'description': null,
        'price_clinic': p.priceClinic,
        'price_home_visit': p.priceHomeVisit,
        'image_url': p.imageUrl,
        'is_active': p.isActive ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();
      await _localDB.cacheProducts(rows);
    } catch (e) {
      debugPrint('[Cache] Failed to cache products: $e');
    }
  }

  // ─── USER ACCOUNTS ────────────────────────────────────────────

  Future<void> cacheUserAccount(AppUser user, {String? email, String? password}) async {
    try {
      await _localDB.saveAccount({
        'id': user.id,
        'username': user.username,
        'full_name': user.name,
        'role_id': user.isAdmin ? 1 : 2,
        'branch_id': user.branchId,
        'branch_name': user.branchName,
        'email': email,
        'password_hash': password, // Plain for MVP
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Cache] User account cached: ${user.username}');
    } catch (e) {
      debugPrint('[Cache] Failed to cache user: $e');
    }
  }

  // ─── HELD ORDERS ──────────────────────────────────────────────

  Future<void> cacheHeldOrders(List<Map<String, dynamic>> orders) async {
    for (final order in orders) {
      try {
        await _localDB.saveHeldOrder({
          'id': order['id'],
          'branch_id': order['branch_id'],
          'cashier_id': order['cashier_id'],
          'items': order['items'] is String
              ? order['items']
              : order['items'].toString(),
          'notes': order['notes'],
          'customer_name': order['customer_name'],
          'hold_order_status': order['hold_order_status'] ?? 'active',
          'created_at': order['created_at'],
          'updated_at': order['updated_at'],
        });
      } catch (e) {
        debugPrint('[Cache] Failed to cache held order: $e');
      }
    }
  }

  // ─── TRANSACTIONS (with fallback) ──────────────────────────────

  Future<List<txn.Transaction>> fetchTransactions() async {
    try {
      final transactions = await _supabase.fetchTransactions();
      // Cache to local DB
      _cacheTransactions(transactions);
      return transactions;
    } catch (e) {
      debugPrint('[Cache] Supabase transactions failed: $e — using local');
      final cached = await _localDB.getAllCachedTransactions();
      if (cached.isEmpty) rethrow;
      return cached.map((row) => txn.Transaction(
        id: row['id'] as String,
        cashierId: row['cashier_id'] as String? ?? '',
        items: [],
        totalAmount: row['total_amount'] as int? ?? 0,
        amountPaid: row['amount_paid'] as int? ?? 0,
        change: row['change_amount'] as int? ?? 0,
        paymentMethod: txn.PaymentMethod.values.firstWhere(
          (m) => m.name == row['payment_method'],
          orElse: () => txn.PaymentMethod.cash,
        ),
        cashierName: '',
        customerName: row['customer_name'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        status: txn.TransactionStatus.values.firstWhere(
          (s) => s.name == row['status'],
          orElse: () => txn.TransactionStatus.completed,
        ),
        printStatus: txn.PrintStatus.values.firstWhere(
          (p) => p.name == row['print_status'],
          orElse: () => txn.PrintStatus.unprinted,
        ),
      )).toList();
    }
  }

  void _cacheTransactions(List<txn.Transaction> transactions) {
    // Fire and forget — don't block
    for (final t in transactions) {
      _localDB.saveOfflineTransaction({
        'id': t.id,
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
        'synced': 1,
      }).catchError((_) {});
    }
  }

  // ─── HELD ORDERS (with fallback) ───────────────────────────────

  Future<List<Map<String, dynamic>>> fetchHeldOrders(String cashierId) async {
    try {
      final orders = await _supabase.fetchHeldOrders(cashierId);
      // Cache to local DB
      _cacheHeldOrdersList(orders);
      return orders.map((o) => {
        'id': o.id,
        'items': o.items.map((i) => i.toJson()).toList(),
        'notes': o.notes,
        'customer_name': o.customerName,
        'hold_order_status': o.status,
        'created_at': o.createdAt.toIso8601String(),
      }).toList();
    } catch (e) {
      debugPrint('[Cache] Supabase held orders failed: $e — using local');
      final cached = await _localDB.getAllCachedHeldOrders();
      if (cached.isEmpty) rethrow;
      return cached;
    }
  }

  void _cacheHeldOrdersList(List<HeldOrder> orders) {
    for (final o in orders) {
      _localDB.saveHeldOrder({
        'id': o.id,
        'items': o.items.map((i) => i.toJson()).toString(),
        'notes': o.notes,
        'customer_name': o.customerName,
        'hold_order_status': o.status,
        'created_at': o.createdAt.toIso8601String(),
        'synced': 1,
      }).catchError((_) {});
    }
  }

  // ─── SYNC ALL TO LOCAL ────────────────────────────────────────
  /// Fetch ALL data from Supabase and write to SQLite cache
  Future<void> syncAllToLocal({String? cashierId}) async {
    debugPrint('[Cache] syncAllToLocal: starting...');
    
    try {
      final products = await _supabase.fetchProducts();
      await _cacheProducts(products);
      debugPrint('[Cache] ✓ Products synced: ${products.length}');
    } catch (e) {
      debugPrint('[Cache] Products sync error: $e');
    }

    try {
      final transactions = await _supabase.fetchTransactions();
      _cacheTransactions(transactions);
      debugPrint('[Cache] ✓ Transactions synced: ${transactions.length}');
    } catch (e) {
      debugPrint('[Cache] Transactions sync error: $e');
    }

    if (cashierId != null) {
      try {
        final orders = await _supabase.fetchHeldOrders(cashierId);
        _cacheHeldOrdersList(orders);
        debugPrint('[Cache] ✓ Held orders synced: ${orders.length}');
      } catch (e) {
        debugPrint('[Cache] Held orders sync error: $e');
      }
    }

    debugPrint('[Cache] syncAllToLocal: complete');
  }
}
