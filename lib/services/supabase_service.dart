import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/held_order.dart';
import '../models/product.dart';
import '../models/transaction.dart' as txn;
import '../models/user.dart';
import '../utils/network_utils.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  void _log(String step, [dynamic data]) {
    // ignore: avoid_print
    debugPrint('[DHBH Supabase] $step${data != null ? ': $data' : ''}');
  }

  // ─── AUTH ──────────────────────────────────────────────────────

  Future<AppUser?> signUp(String email, String password, {
    required String username,
    required String displayName,
    required String role,
    int? branchId,
  }) async {
    _log('signUp', 'email=$email, role=$role, branch=$branchId');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': displayName,
          'name': displayName,
          'role': role,
        },
      );
      final user = response.user;
      if (user == null) {
        _log('signUp FAILED', 'user null');
        return null;
      }
      _log('signUp SUCCESS', 'uid=${user.id}');

      await _client.from('user_profiles').insert({
        'id': user.id,
        'username': username,
        'full_name': displayName,
        'role_id': role == 'admin' ? 1 : 2,
        'branch_id': branchId,
        'is_active': true,
      });

      _log('signUp PROFILE CREATED');
      return AppUser(
        id: user.id,
        username: username,
        name: displayName,
        role: role == 'admin' ? UserRole.admin : UserRole.kasir,
        branchId: branchId,
      );
    } catch (e) {
      _log('signUp ERROR', e.toString());
      rethrow;
    }
  }



  Future<AppUser?> signIn(String email, String password) async {
    _log('signIn', 'email=$email');
    try {
      // Step 1: Check network connectivity
      _log('signIn', 'Step 1: Checking network connectivity...');
      final isOnline = await NetworkUtils.isOnline();
      if (!isOnline) {
        _log('signIn ERROR', 'Device is offline');
        throw Exception('Tidak ada koneksi internet. Periksa WiFi atau mobile data Anda.');
      }
      _log('signIn', '✓ Network connectivity OK');

      // Step 2: Pre-flight DNS check to prevent hanging
      _log('signIn', 'Step 2: Checking DNS resolution...');
      final dnsOk = await NetworkUtils.checkDnsResolution();
      if (!dnsOk) {
        _log('signIn ERROR', 'DNS resolution failed - server unreachable');
        throw Exception('Tidak dapat menjangkau server. Periksa koneksi internet atau coba lagi nanti.');
      }
      _log('signIn', '✓ DNS resolution OK');

      // Step 3: Attempt authentication with timeout
      _log('signIn', 'Step 3: Attempting authentication...');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          _log('signIn TIMEOUT', 'Auth request exceeded 6 seconds (HTTP client: 5s)');
          throw TimeoutException('Server connection timeout. Try again.');
        },
      );
      
      final session = response.session;
      if (session == null) {
        _log('signIn FAILED', 'session null');
        return null;
      }
      _log('signIn SUCCESS', 'uid=${session.user.id}');
      return _fetchUserProfile(session.user.id);
    } on TimeoutException catch (e) {
      _log('signIn TIMEOUT', e.toString());
      rethrow;
    } on Exception catch (e) {
      _log('signIn ERROR', 'Exception: ${e.toString()}');
      rethrow;
    } catch (e) {
      _log('signIn ERROR', 'Unexpected error: ${e.toString()}');
      rethrow;
    }
  }

  Future<AppUser?> _fetchUserProfile(String uid) async {
    _log('fetchUserProfile', 'uid=$uid');
    try {
      final data = await _client
          .from('user_profiles')
          .select('id, username, full_name, is_active, role_id, branch_id, branches!left(name)')
          .eq('id', uid)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              _log('fetchUserProfile TIMEOUT', 'Database query exceeded 6 seconds');
              throw TimeoutException('User profile fetch timeout');
            },
          );

      if (data == null) {
        _log('fetchUserProfile NOT FOUND', 'No profile for uid=$uid');
        return null;
      }

      final roleId = data['role_id'] as int?;
      final roleName = roleId == 1 ? 'admin' : 'kasir';
      final branchData = data['branches'];
      final branchName = (branchData is Map) ? branchData['name'] as String? : null;

      _log('fetchUserProfile SUCCESS', 'username=${data['username']}, role=$roleName, branch=$branchName');

      return AppUser(
        id: data['id'] as String,
        username: data['username'] as String,
        name: data['full_name'] as String,
        role: roleName == 'admin' ? UserRole.admin : UserRole.kasir,
        branchId: data['branch_id'] as int?,
        branchName: branchName,
      );
    } on TimeoutException catch (e) {
      _log('fetchUserProfile TIMEOUT', e.toString());
      rethrow;
    } catch (e) {
      _log('fetchUserProfile ERROR', e.toString());
      rethrow;
    }
  }

  Future<AppUser?> getCurrentUser() async {
    _log('getCurrentUser');
    final session = _client.auth.currentSession;
    if (session == null) {
      _log('getCurrentUser NO SESSION');
      return null;
    }
    _log('getCurrentUser HAS SESSION', 'uid=${session.user.id}');
    return _fetchUserProfile(session.user.id);
  }

  Future<void> signOut() async {
    _log('signOut');
    await _client.auth.signOut();
    _log('signOut DONE');
  }

  // ─── PRODUCTS ───────────────────────────────────────────────────

  Future<List<Product>> fetchProducts() async {
    _log('fetchProducts');
    try {
      final data = await _client
          .from('products')
          .select('''
            id, item_no, name, description, category,
            price_clinic, price_home_visit, image_url, is_active,
            product_categories!left(name)
          ''')
          .order('item_no')
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              _log('fetchProducts TIMEOUT', 'Query exceeded 6 seconds');
              throw TimeoutException('Products fetch timeout');
            },
          );

      _log('fetchProducts SUCCESS', 'count=${data.length}');
      return data.map<Product>((row) {
        String cat = (row['category'] as String?) ?? '';
        if (cat.isEmpty) {
          cat = ((row['product_categories'] as Map?)?.values.firstOrNull as String?) ?? '';
        }
        _log('fetchProducts item', 'id=${row['id']}, name=${row['name']}, category=$cat');
        return Product(
          id: row['id'] as int,
          itemNo: row['item_no'] as int?,
          name: row['name'] as String,
          priceClinic: row['price_clinic'] as int,
          priceHomeVisit: row['price_home_visit'] as int?,
          imageUrl: row['image_url'] as String?,
          isActive: row['is_active'] as bool? ?? true,
          category: cat,
        );
      }).toList();
    } on TimeoutException catch (e) {
      _log('fetchProducts TIMEOUT', e.toString());
      rethrow;
    } catch (e) {
      _log('fetchProducts ERROR', e.toString());
      rethrow;
    }
  }

  Future<Product> addProduct(Product product) async {
    _log('addProduct', product.name);
    try {
      final data = await _client.from('products').insert({
        'name': product.name,
        'price_clinic': product.priceClinic,
        'price_home_visit': product.priceHomeVisit,
        'image_url': product.imageUrl,
        'is_active': product.isActive,
        'category': product.category,
      }).select().single();

      _log('addProduct SUCCESS', 'id=${data['id']}');
      return Product.fromJson(data);
    } catch (e) {
      _log('addProduct ERROR', e.toString());
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    _log('updateProduct', 'id=${product.id}, name=${product.name}');
    try {
      await _client.from('products').update({
        'name': product.name,
        'price_clinic': product.priceClinic,
        'price_home_visit': product.priceHomeVisit,
        'image_url': product.imageUrl,
        'is_active': product.isActive,
        'category': product.category,
      }).eq('id', product.id);
      _log('updateProduct SUCCESS');
    } catch (e) {
      _log('updateProduct ERROR', e.toString());
      rethrow;
    }
  }

  Future<void> deleteProduct(int productId) async {
    _log('deleteProduct', 'id=$productId');
    try {
      await _client.from('products').delete().eq('id', productId);
      _log('deleteProduct SUCCESS');
    } catch (e) {
      _log('deleteProduct ERROR', e.toString());
      rethrow;
    }
  }

  // ─── TRANSACTIONS ───────────────────────────────────────────────

  Future<List<txn.Transaction>> fetchTransactions() async {
    _log('fetchTransactions');
    try {
      final data = await _client
          .from('transactions')
          .select('''
            id, order_no, cashier_id, customer_name,
            total_amount, amount_paid, change_amount,
            payment_method, status, print_status, created_at,
            transaction_items(
              product_id, product_name, quantity,
              unit_price, total_price, is_home_visit, notes
            )
          ''')
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              _log('fetchTransactions TIMEOUT', 'Query exceeded 6 seconds');
              throw TimeoutException('Transactions fetch timeout');
            },
          );

      _log('fetchTransactions SUCCESS', 'count=${data.length}');
      return data.map<txn.Transaction>((row) {
        final items = (row['transaction_items'] as List<dynamic>?)?.map((item) {
          return CartItem.fromJson(item as Map<String, dynamic>);
        }).toList() ?? [];

        return txn.Transaction(
          id: (row['order_no'] as int).toString(),
          orderNo: row['order_no'] as int,
          cashierId: row['cashier_id'] as String? ?? '',
          items: items,
          totalAmount: row['total_amount'] as int,
          amountPaid: row['amount_paid'] as int,
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
            (p) => p.name == (row['print_status'] as String?),
            orElse: () => txn.PrintStatus.unprinted,
          ),
        );
      }).toList();
    } on TimeoutException catch (e) {
      _log('fetchTransactions TIMEOUT', e.toString());
      rethrow;
    } catch (e) {
      _log('fetchTransactions ERROR', e.toString());
      rethrow;
    }
  }

  Future<void> saveTransaction(txn.Transaction transaction) async {
    _log('saveTransaction', 'total=${transaction.totalAmount}');
    try {
      final orderNo = await _getNextOrderNo();

      final dbPaymentMethod = transaction.paymentMethod == txn.PaymentMethod.eWallet
          ? 'e_wallet'
          : transaction.paymentMethod.name;
      final txnData = await _client.from('transactions').insert({
        'order_no': orderNo,
        'cashier_id': transaction.cashierId,
        'branch_id': transaction.branchId,
        'customer_name': transaction.customerName,
        'total_amount': transaction.totalAmount,
        'amount_paid': transaction.amountPaid,
        'change_amount': transaction.change,
        'payment_method': dbPaymentMethod,
        'status': transaction.status.name,
        'print_status': transaction.printStatus.name,
      }).select().single();

      final txnId = txnData['id'] as int;
      _log('saveTransaction CREATED', 'id=$txnId, order_no=$orderNo');

      if (transaction.items.isNotEmpty) {
        final itemsData = transaction.items.map((item) => {
          'transaction_id': txnId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
          'is_home_visit': item.isHomeVisit,
          'notes': item.notes,
        }).toList();

        await _client.from('transaction_items').insert(itemsData);
        _log('saveTransaction ITEMS SAVED', 'count=${itemsData.length}');
      }

      _log('saveTransaction COMPLETE');
    } catch (e) {
      _log('saveTransaction ERROR', e.toString());
      rethrow;
    }
  }

  // ─── HELD ORDERS ───────────────────────────────────────────────

  Future<void> saveHeldOrder(List<CartItem> items, {String? notes, String? customerName, required String cashierId}) async {
    _log('saveHeldOrder', 'items=${items.length}');
    try {
      await _client.from('held_orders').insert({
        'cashier_id': cashierId,
        'items': items.map((item) => item.toJson()).toList(),
        'notes': notes,
        'customer_name': customerName,
        'hold_order_status': 'active',
      });
      _log('saveHeldOrder SUCCESS');
    } catch (e) {
      _log('saveHeldOrder ERROR', e.toString());
      rethrow;
    }
  }

  Future<List<HeldOrder>> fetchHeldOrders(String cashierId) async {
    _log('fetchHeldOrders');
    try {
      final data = await _client
          .from('held_orders')
          .select('id, items, notes, customer_name, hold_order_status, created_at')
          .eq('cashier_id', cashierId)
          .eq('hold_order_status', 'active')
          .order('created_at', ascending: false)
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              _log('fetchHeldOrders TIMEOUT', 'Query exceeded 6 seconds');
              throw TimeoutException('Held orders fetch timeout');
            },
          );

      _log('fetchHeldOrders SUCCESS', 'count=${data.length}');
      return data.map<HeldOrder>((row) => HeldOrder.fromJson(Map<String, dynamic>.from(row))).toList();
    } on TimeoutException catch (e) {
      _log('fetchHeldOrders TIMEOUT', e.toString());
      return [];
    } catch (e) {
      _log('fetchHeldOrders ERROR', e.toString());
      return [];
    }
  }

  Future<void> completeHeldOrder(int orderId) async {
    _log('completeHeldOrder', 'id=$orderId');
    try {
      await _client.from('held_orders').update({'hold_order_status': 'completed'}).eq('id', orderId);
      _log('completeHeldOrder SUCCESS');
    } catch (e) {
      _log('completeHeldOrder ERROR', e.toString());
    }
  }

  // ─── BRANCHES ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    _log('fetchBranches');
    try {
      final data = await _client.from('branches').select('id, name').order('id');
      return data.map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      _log('fetchBranches ERROR', e.toString());
      return [];
    }
  }

  // ─── REFUNDS ────────────────────────────────────────────────────

  Future<void> processRefund({
    required int transactionId,
    required String reason,
    required int refundAmount,
    required String cashierId,
    String refundMethod = 'cash',
  }) async {
    _log('processRefund', 'txn=$transactionId, amount=$refundAmount');
    try {
      await _client.from('refunds').insert({
        'transaction_id': transactionId,
        'cashier_id': cashierId,
        'reason': reason,
        'refund_amount': refundAmount,
        'refund_method': refundMethod,
      });
      await _client.from('transactions').update({'status': 'refunded'}).eq('id', transactionId);
      _log('processRefund SUCCESS');
    } catch (e) {
      _log('processRefund ERROR', e.toString());
      rethrow;
    }
  }

  // ─── ADMIN: DAILY SUMMARIES ─────────────────────────────────────

  Future<Map<String, dynamic>> fetchDailySummary() async {
    _log('fetchDailySummary');
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch today's completed transactions (no aggregate functions via REST)
      final todayTxns = await _client
          .from('transactions')
          .select('total_amount, amount_paid, payment_method')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .eq('status', 'completed');

      final txCount = todayTxns.length;
      int revenue = 0;
      int cashTotal = 0, debitTotal = 0, creditTotal = 0, qrisTotal = 0, ewalletTotal = 0;

      for (final row in todayTxns) {
        final amount = row['total_amount'] as int? ?? 0;
        revenue += amount;
        final method = row['payment_method'] as String?;
        if (method == 'cash') {
          cashTotal += amount;
        } else if (method == 'debit') {
          debitTotal += amount;
        } else if (method == 'credit') {
          creditTotal += amount;
        } else if (method == 'qris') {
          qrisTotal += amount;
        } else if (method == 'e_wallet') {
          ewalletTotal += amount;
        }
      }

      // Fetch today's refunds (no aggregate functions via REST)
      final todayRefunds = await _client
          .from('refunds')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      _log('fetchDailySummary', 'transaksi=$txCount, revenue=$revenue, refund=${todayRefunds.length}');
      return {
        'tanggal': today,
        'total_transaksi': txCount,
        'total_revenue': revenue,
        'cash': cashTotal,
        'debit': debitTotal,
        'credit': creditTotal,
        'qris': qrisTotal,
        'e_wallet': ewalletTotal,
        'total_refund': todayRefunds.length,
      };
    } catch (e) {
      _log('fetchDailySummary ERROR', e.toString());
      return {};
    }
  }

  // ─── ADMIN: ACTIVITY LOGS ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchActivityLogs() async {
    _log('fetchActivityLogs');
    try {
      final data = await _client
          .from('activity_logs')
          .select('id, user_id, action, details, created_at')
          .order('created_at', ascending: false)
          .limit(50);

      // Fetch user names separately (avoids RLS join issues)
      final userIds = data.map((r) => r['user_id'] as String?).whereType<String>().toSet().toList();
      final userMap = <String, String>{};
      if (userIds.isNotEmpty) {
        final users = await _client
            .from('user_profiles')
            .select('id, full_name')
            .inFilter('id', userIds);
        for (final u in users) {
          userMap[u['id'] as String] = u['full_name'] as String;
        }
      }

      return data.map<Map<String, dynamic>>((r) {
        final map = Map<String, dynamic>.from(r);
        map['user_name'] = userMap[r['user_id'] as String?] ?? 'Unknown';
        return map;
      }).toList();
    } catch (e) {
      _log('fetchActivityLogs ERROR', e.toString());
      return [];
    }
  }

  // ─── ADMIN: ALL TRANSACTIONS ───────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllTransactions() async {
    _log('fetchAllTransactions');
    try {
      final data = await _client
          .from('transactions')
          .select('id, order_no, cashier_id, customer_name, total_amount, amount_paid, change_amount, payment_method, status, created_at')
          .order('created_at', ascending: false)
          .limit(100);

      final userIds = data.map((r) => r['cashier_id'] as String?).whereType<String>().toSet().toList();
      final userMap = <String, String>{};
      if (userIds.isNotEmpty) {
        final users = await _client
            .from('user_profiles')
            .select('id, full_name')
            .inFilter('id', userIds);
        for (final u in users) {
          userMap[u['id'] as String] = u['full_name'] as String;
        }
      }

      return data.map<Map<String, dynamic>>((r) {
        final map = Map<String, dynamic>.from(r);
        map['cashier_name'] = userMap[r['cashier_id'] as String?] ?? '';
        return map;
      }).toList();
    } catch (e) {
      _log('fetchAllTransactions ERROR', e.toString());
      return [];
    }
  }

  // ─── LOG ACTIVITY (from app) ───────────────────────────────────

  Future<void> logActivity(String userId, String action, {Map<String, dynamic>? details}) async {
    _log('logActivity', 'action=$action');
    try {
      await _client.from('activity_logs').insert({
        'user_id': userId,
        'action': action,
        'details': details,
      });
    } catch (e) {
      _log('logActivity ERROR', e.toString());
    }
  }

  Future<int> _getNextOrderNo() async {
    _log('getNextOrderNo');
    try {
      final data = await _client
          .from('transactions')
          .select('order_no')
          .order('order_no', ascending: false)
          .limit(1)
          .maybeSingle();

      final next = (data?['order_no'] as int? ?? 0) + 1;
      _log('getNextOrderNo', 'next=$next');
      return next;
    } catch (e) {
      _log('getNextOrderNo ERROR', e.toString());
      return 1;
    }
  }

  // ─── PRINT STATUS ──────────────────────────────────────────────

  Future<void> updatePrintStatus(int orderNo, String newStatus) async {
    _log('updatePrintStatus', 'orderNo=$orderNo, status=$newStatus');
    try {
      await _client
          .from('transactions')
          .update({'print_status': newStatus})
          .eq('order_no', orderNo);
      _log('updatePrintStatus SUCCESS');
    } catch (e) {
      _log('updatePrintStatus ERROR', e.toString());
      rethrow;
    }
  }

  Future<void> updateMultiplePrintStatus(List<int> orderNos, String newStatus) async {
    _log('updateMultiplePrintStatus', 'count=${orderNos.length}, status=$newStatus');
    try {
      await _client
          .from('transactions')
          .update({'print_status': newStatus})
          .inFilter('order_no', orderNos);
      _log('updateMultiplePrintStatus SUCCESS');
    } catch (e) {
      _log('updateMultiplePrintStatus ERROR', e.toString());
      rethrow;
    }
  }

  // ─── CLOSING REPORT ──────────────────────────────────────────────

  /// Get products sold grouped by product for a given date
  Future<List<Map<String, dynamic>>> getProductsSold(DateTime date) async {
    _log('getProductsSold', 'date=${_formatDate(date)}');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _client
          .from('transaction_items')
          .select('product_id, product_name, quantity, total_price, is_home_visit')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      // Aggregate by product
      final Map<String, Map<String, dynamic>> aggregated = {};
      for (final row in data) {
        final name = row['product_name'] as String? ?? '';
        final isHomeVisit = row['is_home_visit'] as bool? ?? false;
        final key = '${name}_$isHomeVisit';
        
        if (!aggregated.containsKey(key)) {
          aggregated[key] = {
            'name': isHomeVisit ? '$name (Home Visit)' : name,
            'qty': 0,
            'total': 0,
          };
        }
        aggregated[key]!['qty'] = (aggregated[key]!['qty'] as int) + (row['quantity'] as int? ?? 0);
        aggregated[key]!['total'] = (aggregated[key]!['total'] as int) + (row['total_price'] as int? ?? 0);
      }

      return aggregated.values.toList()
        ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    } catch (e) {
      _log('getProductsSold ERROR', e.toString());
      return [];
    }
  }

  /// Get payment breakdown for a given date
  Future<List<Map<String, dynamic>>> getPaymentBreakdown(DateTime date) async {
    _log('getPaymentBreakdown', 'date=${_formatDate(date)}');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await _client
          .from('transactions')
          .select('payment_method, total_amount')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .eq('status', 'completed');

      final Map<String, int> aggregated = {};
      for (final row in data) {
        final method = row['payment_method'] as String? ?? 'cash';
        aggregated[method] = (aggregated[method] ?? 0) + (row['total_amount'] as int? ?? 0);
      }

      return aggregated.entries.map((e) => {
        'method': e.key == 'e_wallet' ? 'E-Wallet' : e.key.substring(0, 1).toUpperCase() + e.key.substring(1),
        'amount': e.value,
      }).toList();
    } catch (e) {
      _log('getPaymentBreakdown ERROR', e.toString());
      return [];
    }
  }

  /// Get transaction counts for closing report
  Future<Map<String, int>> getTransactionCounts(DateTime date) async {
    _log('getTransactionCounts', 'date=${_formatDate(date)}');
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final allTx = await _client
          .from('transactions')
          .select('status')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      int completed = 0, held = 0;
      for (final row in allTx) {
        final status = row['status'] as String? ?? '';
        if (status == 'completed') completed++;
        if (status == 'held') held++;
      }

      return {'completed': completed, 'held': held};
    } catch (e) {
      _log('getTransactionCounts ERROR', e.toString());
      return {'completed': 0, 'held': 0};
    }
  }

  /// Save cashier shift
  Future<int> saveShift(Map<String, dynamic> shift) async {
    _log('saveShift');
    try {
      final data = await _client.from('cashier_shifts').insert(shift).select().single();
      return data['id'] as int;
    } catch (e) {
      _log('saveShift ERROR', e.toString());
      rethrow;
    }
  }

  /// Update shift waktu tutup
  Future<void> updateShiftWaktuTutup(int id, DateTime waktuTutup) async {
    _log('updateShiftWaktuTutup', 'id=$id');
    try {
      await _client.from('cashier_shifts').update({
        'waktu_tutup': waktuTutup.toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      _log('updateShiftWaktuTutup ERROR', e.toString());
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
