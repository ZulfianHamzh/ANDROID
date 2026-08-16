import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as txn;
import '../models/cart_item.dart';
import '../services/supabase_service.dart';

/// Repository for Transaction operations.
/// Saves and reads directly from Supabase — no local cache or sync queue.
class TransactionRepository {
  final SupabaseService _supabase;

  TransactionRepository(this._supabase);

  Future<void> _log(String message) async {
    debugPrint('[Repo:Transaction] $message');
  }

  /// Get transactions directly from Supabase.
  Future<List<txn.Transaction>> getTransactions({int? branchId}) async {
    await _log('getTransactions');
    return await _supabase.fetchTransactions(branchId: branchId);
  }

  /// Save a transaction directly to Supabase and return it with the real
  /// order number assigned by the database (so receipts/history show the
  /// order number instead of a temporary local UUID).
  Future<txn.Transaction> saveTransaction({
    required String cashierId,
    int? branchId,
    required List<CartItem> items,
    required int totalAmount,
    int discount = 0,
    required int amountPaid,
    required int change,
    required txn.PaymentMethod paymentMethod,
    required String cashierName,
    List<String>? customerNames,
    List<String>? terapisIds,
    List<String>? terapisNames,
    String? notes,
    String? branchName,
  }) async {
    await _log('saveTransaction: total=$totalAmount');

    final transaction = txn.Transaction(
      id: '',
      cashierId: cashierId,
      branchId: branchId,
      items: List.from(items),
      totalAmount: totalAmount,
      discount: discount,
      amountPaid: amountPaid,
      change: change,
      paymentMethod: paymentMethod,
      cashierName: cashierName,
      customerNames: customerNames,
      terapisIds: terapisIds,
      terapisNames: terapisNames,
      notes: notes,
      branchName: branchName,
      createdAt: DateTime.now(),
    );

    final orderNo = await _supabase.saveTransaction(transaction);
    await _log('✓ Transaction saved to Supabase (order #$orderNo)');

    // Return a transaction whose id/orderNo match what the DB stores, the
    // same shape as transactions loaded via fetchTransactions().
    return txn.Transaction(
      id: orderNo.toString(),
      orderNo: orderNo,
      cashierId: cashierId,
      branchId: branchId,
      items: List.from(items),
      totalAmount: totalAmount,
      discount: discount,
      amountPaid: amountPaid,
      change: change,
      paymentMethod: paymentMethod,
      cashierName: cashierName,
      customerNames: customerNames,
      terapisIds: terapisIds,
      terapisNames: terapisNames,
      notes: notes,
      branchName: branchName,
      createdAt: transaction.createdAt,
    );
  }

  /// Update print status in Supabase.
  Future<void> updatePrintStatus(int orderNo, String status) async {
    try {
      await _supabase.updatePrintStatus(orderNo, status);
    } catch (e) {
      await _log('✗ Update print status failed: $e');
    }
  }

  /// Update multiple print statuses.
  Future<void> updateMultiplePrintStatus(List<int> orderNos, String status) async {
    try {
      await _supabase.updateMultiplePrintStatus(orderNos, status);
    } catch (e) {
      await _log('✗ Update multiple print status failed: $e');
    }
  }
}
