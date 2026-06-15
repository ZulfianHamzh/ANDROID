import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/held_order.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/thermal_printer_service.dart';
import '../services/bluetooth_service.dart';
import '../services/cache_service.dart';
import '../services/local_database_service.dart';

const _all = '';

class PosProvider extends StateNotifier<PosState> {
  final SupabaseService _supabase;
  final CacheService _cache;
  final LocalDatabaseService _localDB = LocalDatabaseService();
  static const _uuid = Uuid();

  PosProvider(this._supabase)
      : _cache = CacheService(_supabase),
        super(PosState());

  // ─── AUTH ───────────────────────────────────────────────────────

  Future<String?> login(String email, String password) async {
    debugPrint('[DHBH Provider] login: email=$email');
    state = state.copyWith(isLoading: true);
    try {
      final user = await _supabase
          .signIn(email, password)
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () {
              debugPrint('[DHBH Provider] login TIMEOUT after 12 seconds');
              throw TimeoutException('Login timeout: Server tidak merespons dalam waktu yang ditentukan');
            },
          );
      if (user == null) {
        debugPrint('[DHBH Provider] login FAILED: user null');
        state = state.copyWith(isLoading: false);
        return 'Email atau password salah';
      }
      debugPrint('[DHBH Provider] login SUCCESS: ${user.name} (${user.role.name})');
      state = state.copyWith(currentUser: user, isLoading: false);
      _supabase.logActivity(user.id, 'login', details: {'email': email});
      
      // Cache user account for offline login
      _cache.cacheUserAccount(user, email: email, password: password);
      
      return null;
    } on TimeoutException catch (e) {
      debugPrint('[DHBH Provider] login TIMEOUT: ${e.toString()}');
      state = state.copyWith(isLoading: false);
      return e.toString();
    } catch (e) {
      debugPrint('[DHBH Provider] login ERROR: $e');
      state = state.copyWith(isLoading: false);
      final errorMsg = e.toString();
      // Check if it's a network error
      if (errorMsg.contains('offline') || 
          errorMsg.contains('internet') || 
          errorMsg.contains('koneksi')) {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }
      return 'Gagal login: $errorMsg';
    }
  }

  /// Login offline — verifikasi password dari SQLite
  Future<AppUser?> offlineLogin(String email, String password) async {
    debugPrint('[DHBH Provider] offlineLogin: email=$email');
    try {
      final accounts = await _localDB.getAllAccounts();
      for (final account in accounts) {
        final accountEmail = account['email'] as String?;
        final accountPassword = account['password_hash'] as String?;
        if (accountEmail == email && accountPassword == password) {
          final user = AppUser(
            id: account['id'] as String,
            username: account['username'] as String? ?? email,
            name: account['full_name'] as String? ?? email,
            role: (account['role_id'] as int?) == 1 ? UserRole.admin : UserRole.kasir,
            branchId: account['branch_id'] as int?,
            branchName: account['branch_name'] as String?,
          );
          state = state.copyWith(currentUser: user, isLoading: false);
          debugPrint('[DHBH Provider] offlineLogin SUCCESS: ${user.name}');
          return user;
        }
      }
      debugPrint('[DHBH Provider] offlineLogin FAILED: account not found');
      return null;
    } catch (e) {
      debugPrint('[DHBH Provider] offlineLogin ERROR: $e');
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('[DHBH Provider] logout');
    await _supabase.signOut();
    state = PosState();
    debugPrint('[DHBH Provider] logout DONE');
  }

  Future<void> checkSession() async {
    // Auto logout on restart — no session persist
    debugPrint('[DHBH Provider] checkSession: skipped (auto-logout on restart)');
    state = PosState();
  }

  // ─── SEARCH & FILTER ────────────────────────────────────────────

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setMenuSelectedCategory(String category) {
    state = state.copyWith(menuSelectedCategory: category);
  }

  List<Product> filteredProducts(bool showInactive, {bool forMenu = false}) {
    var products = showInactive
        ? state.products
        : state.products.where((p) => p.isActive).toList();
    final category = forMenu ? state.menuSelectedCategory : state.selectedCategory;
    if (category.isNotEmpty) {
      products = products.where((p) => p.category == category).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    return products;
  }

  List<String> get categories {
    return state.products
        .map((p) => p.category)
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort();
  }

  // ─── PRODUCTS ───────────────────────────────────────────────────

  Future<void> loadProducts() async {
    debugPrint('[DHBH Provider] loadProducts + loadTransactions');
    state = state.copyWith(isLoading: true);
    
    // Load each data source independently — one failure doesn't block others
    List<Product> products = state.products;
    List<Transaction> transactions = state.transactions;
    List<HeldOrder> heldOrders = state.heldOrders;
    
    // Products (with cache fallback)
    try {
      products = await _cache.fetchProducts();
    } catch (e) {
      debugPrint('[DHBH Provider] products load ERROR: $e — keeping existing');
    }
    
    // Transactions (with cache fallback)
    try {
      transactions = await _cache.fetchTransactions();
    } catch (e) {
      debugPrint('[DHBH Provider] transactions load ERROR: $e — keeping existing');
    }
    
    // Held orders (with cache fallback)
    try {
      final heldData = await _cache.fetchHeldOrders(state.currentUser?.id ?? '');
      heldOrders = heldData.map((h) {
        final itemsRaw = h['items'] as List<dynamic>? ?? [];
        return HeldOrder(
          id: (h['id'] as int?) ?? 0,
          items: itemsRaw.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
          notes: h['notes'] as String?,
          customerName: h['customer_name'] as String?,
          status: h['hold_order_status'] as String? ?? 'active',
          createdAt: DateTime.tryParse(h['created_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[DHBH Provider] held orders load ERROR: $e — keeping existing');
    }
    
    debugPrint('[DHBH Provider] loaded: ${products.length} products, ${transactions.length} transactions, ${heldOrders.length} held');
    state = state.copyWith(
      products: products,
      transactions: transactions,
      heldOrders: heldOrders,
      isLoading: false,
    );
    
    // Auto-sync all data to SQLite when online (fire and forget)
    _cache.syncAllToLocal(cashierId: state.currentUser?.id);
  }

  // ─── CART ───────────────────────────────────────────────────────

  void addToCart(Product product, {bool isHomeVisit = false}) {
    final existingIndex = state.cartItems.indexWhere(
      (item) => item.product.id == product.id && item.isHomeVisit == isHomeVisit,
    );
    final updatedCart = [...state.cartItems];
    if (existingIndex >= 0) {
      updatedCart[existingIndex] = CartItem(
        product: updatedCart[existingIndex].product,
        quantity: updatedCart[existingIndex].quantity + 1,
        notes: updatedCart[existingIndex].notes,
        isHomeVisit: updatedCart[existingIndex].isHomeVisit,
      );
    } else {
      updatedCart.add(CartItem(product: product, isHomeVisit: isHomeVisit));
    }
    state = state.copyWith(cartItems: updatedCart);
  }

  void removeFromCart(int index) {
    final updatedCart = [...state.cartItems]..removeAt(index);
    state = state.copyWith(cartItems: updatedCart);
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeFromCart(index);
      return;
    }
    final updatedCart = [...state.cartItems];
    updatedCart[index] = CartItem(
      product: updatedCart[index].product,
      quantity: quantity,
      notes: updatedCart[index].notes,
      isHomeVisit: updatedCart[index].isHomeVisit,
    );
    state = state.copyWith(cartItems: updatedCart);
  }

  void updateCartItemNotes(int index, String? notes) {
    final updatedCart = [...state.cartItems];
    updatedCart[index] = CartItem(
      product: updatedCart[index].product,
      quantity: updatedCart[index].quantity,
      notes: notes,
      isHomeVisit: updatedCart[index].isHomeVisit,
    );
    state = state.copyWith(cartItems: updatedCart);
  }

  int get cartTotal => state.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get cartItemCount => state.cartItems.fold(0, (sum, item) => sum + item.quantity);

  // ─── TRANSACTIONS ───────────────────────────────────────────────

  Future<void> completeTransaction({
    required int amountPaid,
    required PaymentMethod paymentMethod,
    String? customerName,
  }) async {
    if (state.currentUser == null) {
      debugPrint('[DHBH Provider] completeTransaction SKIP: no user');
      return;
    }
    debugPrint('[DHBH Provider] completeTransaction: total=$cartTotal, method=${paymentMethod.name}');
    
    // Generate local UUID for offline compatibility
    final localId = _uuid.v4();
    
    final transaction = Transaction(
      id: localId,
      cashierId: state.currentUser!.id,
      branchId: state.currentUser!.branchId,
      items: List.from(state.cartItems),
      totalAmount: cartTotal,
      amountPaid: amountPaid,
      change: amountPaid - cartTotal,
      paymentMethod: paymentMethod,
      cashierName: state.currentUser!.name,
      customerName: customerName,
      branchName: state.currentUser?.branchName,
      createdAt: DateTime.now(),
    );
    
    bool savedToCloud = false;
    try {
      await _supabase.saveTransaction(transaction);
      debugPrint('[DHBH Provider] completeTransaction SUCCESS (cloud)');
      savedToCloud = true;
    } catch (e) {
      debugPrint('[DHBH Provider] completeTransaction ERROR: $e');
    }
    
    // Always save to local SQLite
    try {
      await _localDB.saveOfflineTransaction({
        'id': localId,
        'order_no': null, // Will be assigned on sync
        'branch_id': transaction.branchId,
        'cashier_id': transaction.cashierId,
        'customer_name': transaction.customerName,
        'total_amount': transaction.totalAmount,
        'amount_paid': transaction.amountPaid,
        'change_amount': transaction.change,
        'payment_method': transaction.paymentMethod.name,
        'status': transaction.status.name,
        'notes': null,
        'print_status': transaction.printStatus.name,
        'created_at': transaction.createdAt.toIso8601String(),
        'synced': savedToCloud ? 1 : 0,
      });
      
      // If cloud save failed, add to pending sync queue
      if (!savedToCloud) {
        await _localDB.addToSyncQueue(
          action: 'create_transaction',
          tableName: 'transactions',
          recordId: localId,
          payload: {
            'id': localId,
            'cashier_id': transaction.cashierId,
            'branch_id': transaction.branchId,
            'customer_name': transaction.customerName,
            'items': transaction.items.map((item) => item.toJson()).toList(),
            'total_amount': transaction.totalAmount,
            'amount_paid': transaction.amountPaid,
            'change_amount': transaction.change,
            'payment_method': transaction.paymentMethod.name,
            'status': transaction.status.name,
            'print_status': transaction.printStatus.name,
            'created_at': transaction.createdAt.toIso8601String(),
          },
        );
        debugPrint('[DHBH Provider] Transaction queued for sync');
      }
    } catch (e) {
      debugPrint('[DHBH Provider] Local save error: $e');
    }
    
    // Add to local state
    state = state.copyWith(
      cartItems: [],
      pendingCustomerName: null,
      transactions: [...state.transactions, transaction],
    );
    debugPrint('[DHBH Provider] cart cleared, ${state.transactions.length} total transactions');
    
    // Auto-print receipt if printer is connected
    _tryAutoPrint(transaction);
  }

  Future<void> _tryAutoPrint(Transaction transaction) async {
    try {
      final bluetooth = BluetoothService();
      if (!bluetooth.isConnected) {
        debugPrint('[DHBH Provider] auto-print SKIP: printer not connected');
        return;
      }
      debugPrint('[DHBH Provider] auto-print: printing receipt...');
      await printTransaction(transaction);
    } catch (e) {
      debugPrint('[DHBH Provider] auto-print ERROR: $e');
    }
  }

  // ─── HELD ORDERS ───────────────────────────────────────────────

  Future<void> holdCurrentOrder({String? notes, String? customerName}) async {
    if (state.cartItems.isEmpty) return;
    debugPrint('[DHBH Provider] holdCurrentOrder: ${state.cartItems.length} items');

    bool savedToCloud = false;

    try {
      await _supabase.saveHeldOrder(
        List.from(state.cartItems),
        notes: notes,
        customerName: customerName,
        cashierId: state.currentUser?.id ?? '',
      );
      debugPrint('[DHBH Provider] holdCurrentOrder SUCCESS');
      savedToCloud = true;
    } catch (e) {
      debugPrint('[DHBH Provider] holdCurrentOrder ERROR: $e — saving locally');
    }

    final held = HeldOrder(
      id: DateTime.now().millisecondsSinceEpoch,
      items: List.from(state.cartItems),
      notes: notes,
      customerName: customerName,
      createdAt: DateTime.now(),
    );

    // Save locally
    if (!savedToCloud) {
      try {
        await _localDB.saveHeldOrder({
          'id': held.id,
          'branch_id': state.currentUser?.branchId,
          'cashier_id': state.currentUser?.id,
          'items': held.items.map((item) => item.toJson()).toString(),
          'notes': notes,
          'customer_name': customerName,
          'hold_order_status': 'active',
          'created_at': held.createdAt.toIso8601String(),
          'synced': 0,
        });
        await _localDB.addToSyncQueue(
          action: 'create_held_order',
          tableName: 'held_orders',
          recordId: held.id.toString(),
          payload: {
            'id': held.id,
            'cashier_id': state.currentUser?.id,
            'branch_id': state.currentUser?.branchId,
            'items': held.items.map((item) => item.toJson()).toList(),
            'notes': notes,
            'customer_name': customerName,
          },
        );
      } catch (e) {
        debugPrint('[DHBH Provider] Local held order save error: $e');
      }
    }

    state = state.copyWith(
      cartItems: [],
      heldOrders: [held, ...state.heldOrders],
    );
  }

  Future<void> retrieveHeldOrder(int index) async {
    final order = state.heldOrders[index];
    debugPrint('[DHBH Provider] retrieveHeldOrder: id=${order.id}, customer=${order.customerName}');

    state = state.copyWith(
      cartItems: List.from(order.items),
      pendingCustomerName: order.customerName,
    );

    final updatedOrders = [...state.heldOrders]..removeAt(index);
    state = state.copyWith(heldOrders: updatedOrders);

    if (order.id > 0) {
      try {
        await _supabase.completeHeldOrder(order.id);
      } catch (_) {}
      // Also update local SQLite regardless of network
      try {
        await _localDB.completeLocalHeldOrder(order.id);
      } catch (_) {}
    }
  }

  Future<void> deleteHeldOrder(int index) async {
    final order = state.heldOrders[index];
    final updatedOrders = [...state.heldOrders]..removeAt(index);
    state = state.copyWith(heldOrders: updatedOrders);

    if (order.id > 0) {
      try {
        await _supabase.completeHeldOrder(order.id);
      } catch (_) {}
      try {
        await _localDB.deleteLocalHeldOrder(order.id);
      } catch (_) {}
    }
  }

  Future<void> loadHeldOrders() async {
    if (state.currentUser == null) return;
    final orders = await _supabase.fetchHeldOrders(state.currentUser!.id);
    state = state.copyWith(heldOrders: orders);
  }

  // ─── PRODUCT CRUD (Admin) ──────────────────────────────────────

  Future<void> addProduct(Product product) async {
    debugPrint('[DHBH Provider] addProduct: ${product.name}');
    try {
      final saved = await _supabase.addProduct(product);
      debugPrint('[DHBH Provider] addProduct SUCCESS: id=${saved.id}');
      state = state.copyWith(products: [...state.products, saved]);
    } catch (e) {
      debugPrint('[DHBH Provider] addProduct ERROR: $e — falling back to local');
      final maxId = state.products.fold(0, (max, p) => p.id > max ? p.id : max);
      final newProduct = product.copyWith(id: maxId + 1);
      state = state.copyWith(products: [...state.products, newProduct]);
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    debugPrint('[DHBH Provider] updateProduct: id=${updatedProduct.id}, name=${updatedProduct.name}');
    try {
      await _supabase.updateProduct(updatedProduct);
      debugPrint('[DHBH Provider] updateProduct SUCCESS');
    } catch (e) {
      debugPrint('[DHBH Provider] updateProduct ERROR: $e');
    }
    final updatedList = state.products.map((p) =>
      p.id == updatedProduct.id ? updatedProduct : p,
    ).toList();
    state = state.copyWith(products: updatedList);
  }

  Future<void> deleteProduct(int productId) async {
    debugPrint('[DHBH Provider] deleteProduct: id=$productId');
    try {
      await _supabase.deleteProduct(productId);
      debugPrint('[DHBH Provider] deleteProduct SUCCESS');
    } catch (e) {
      debugPrint('[DHBH Provider] deleteProduct ERROR: $e');
    }
    final updatedList = state.products.where((p) => p.id != productId).toList();
    state = state.copyWith(products: updatedList);
  }

  // ─── TODAY STATS ────────────────────────────────────────────────

  int get todayTransactionCount {
    final today = DateTime.now();
    return state.transactions.where((t) =>
      t.createdAt.year == today.year &&
      t.createdAt.month == today.month &&
      t.createdAt.day == today.day &&
      t.status == TransactionStatus.completed
    ).length;
  }

  int get todayRevenue {
    final today = DateTime.now();
    return state.transactions.where((t) =>
      t.createdAt.year == today.year &&
      t.createdAt.month == today.month &&
      t.createdAt.day == today.day &&
      t.status == TransactionStatus.completed
    ).fold(0, (sum, t) => sum + t.totalAmount);
  }

  // ─── THERMAL PRINTER ────────────────────────────────────────────

  Future<bool> printTransaction(Transaction transaction) async {
    debugPrint('[DHBH Provider] printTransaction: id=${transaction.id}, orderNo=${transaction.orderNo}');
    bool printSuccess = false;
    try {
      final printer = ThermalPrinterService();
      printSuccess = await printer.printTransaction(transaction);
    } catch (e) {
      debugPrint('[DHBH Provider] printTransaction print error: $e');
    }
    
    // Always try to update status in DB (don't let DB failure affect print result)
    if (transaction.orderNo != null) {
      try {
        await _supabase.updatePrintStatus(
          transaction.orderNo!,
          printSuccess ? PrintStatus.printed.name : PrintStatus.failed.name,
        );
      } catch (e) {
        debugPrint('[DHBH Provider] printTransaction DB update error: $e');
      }
    } else {
      debugPrint('[DHBH Provider] printTransaction SKIP DB update: no orderNo (offline)');
    }
    
    // Update local state regardless
    final updatedTrans = state.transactions.map((t) {
      if (t.id == transaction.id) {
        return Transaction(
          id: t.id,
          orderNo: t.orderNo,
          cashierId: t.cashierId,
          items: t.items,
          totalAmount: t.totalAmount,
          amountPaid: t.amountPaid,
          change: t.change,
          paymentMethod: t.paymentMethod,
          cashierName: t.cashierName,
          customerName: t.customerName,
          branchId: t.branchId,
          createdAt: t.createdAt,
          status: t.status,
          printStatus: printSuccess ? PrintStatus.printed : PrintStatus.failed,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(transactions: updatedTrans);
    
    debugPrint('[DHBH Provider] printTransaction ${printSuccess ? "SUCCESS" : "FAILED"}');
    return printSuccess;
  }

  Future<void> printUnprintedTransactions() async {
    debugPrint('[DHBH Provider] printUnprintedTransactions');
    final unprintedTrans = state.transactions
        .where((t) => t.printStatus == PrintStatus.unprinted)
        .toList();
    
    if (unprintedTrans.isEmpty) {
      debugPrint('[DHBH Provider] No unprinted transactions');
      return;
    }

    final printer = ThermalPrinterService();
    int successCount = 0;
    
    for (final transaction in unprintedTrans) {
      final success = await printer.printTransaction(transaction);
      if (success && transaction.orderNo != null) {
        successCount++;
        await _supabase.updatePrintStatus(transaction.orderNo!, PrintStatus.printed.name);
      }
    }

    debugPrint('[DHBH Provider] printUnprintedTransactions: $successCount/${unprintedTrans.length} printed');
    
    // Refresh transactions
    await loadProducts();
  }
}

class PosState {
  final AppUser? currentUser;
  final List<Product> products;
  final List<CartItem> cartItems;
  final List<Transaction> transactions;
  final List<HeldOrder> heldOrders;
  final String? pendingCustomerName;
  final String searchQuery;
  final String selectedCategory;
  final String menuSelectedCategory;
  final bool isLoading;

  PosState({
    this.currentUser,
    this.products = const [],
    this.cartItems = const [],
    this.transactions = const [],
    this.heldOrders = const [],
    this.pendingCustomerName,
    this.searchQuery = '',
    this.selectedCategory = _all,
    this.menuSelectedCategory = _all,
    this.isLoading = false,
  });

  PosState copyWith({
    AppUser? currentUser,
    List<Product>? products,
    List<CartItem>? cartItems,
    List<Transaction>? transactions,
    List<HeldOrder>? heldOrders,
    String? pendingCustomerName,
    String? searchQuery,
    String? selectedCategory,
    String? menuSelectedCategory,
    bool? isLoading,
  }) {
    return PosState(
      currentUser: currentUser ?? this.currentUser,
      products: products ?? this.products,
      cartItems: cartItems ?? this.cartItems,
      transactions: transactions ?? this.transactions,
      heldOrders: heldOrders ?? this.heldOrders,
      pendingCustomerName: pendingCustomerName ?? this.pendingCustomerName,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      menuSelectedCategory: menuSelectedCategory ?? this.menuSelectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    final client = Supabase.instance.client;
    debugPrint('[DHBH Provider] SupabaseClient obtained successfully');
    return client;
  } catch (e) {
    debugPrint('[DHBH Provider] ⚠️ Error getting SupabaseClient: $e');
    rethrow;
  }
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

final posProvider = StateNotifierProvider<PosProvider, PosState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PosProvider(supabase);
});
