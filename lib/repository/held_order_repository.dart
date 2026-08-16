import 'package:flutter/foundation.dart';
import '../models/held_order.dart';
import '../models/cart_item.dart';
import '../services/supabase_service.dart';

/// Repository for Held Order operations.
/// Reads and writes directly to Supabase — no local cache.
class HeldOrderRepository {
  final SupabaseService _supabase;

  HeldOrderRepository(this._supabase);

  Future<void> _log(String message) async {
    debugPrint('[Repo:HeldOrder] $message');
  }

  /// Get held orders from Supabase.
  Future<List<HeldOrder>> getHeldOrders({required String cashierId}) async {
    await _log('getHeldOrders');
    return await _supabase.fetchHeldOrders(cashierId);
  }

  /// Save a held order to Supabase.
  Future<HeldOrder> saveHeldOrder({
    required String cashierId,
    int? branchId,
    required List<CartItem> items,
    String? notes,
    List<String>? customerNames,
    String? customerName,
  }) async {
    await _log('saveHeldOrder');

    final dbId = await _supabase.saveHeldOrder(items,
      notes: notes,
      customerNames: customerNames,
      customerName: customerName,
      cashierId: cashierId,
    );

    // Use the real DB id when available so retrieve/delete can update the
    // correct row (a fake local id would silently not match any row, leaving
    // the held order 'active' forever — it reappeared after app restart).
    return HeldOrder(
      id: dbId ?? DateTime.now().millisecondsSinceEpoch,
      items: List.from(items),
      notes: notes,
      customerNames: customerNames,
      customerName: customerName,
      createdAt: DateTime.now(),
    );
  }

  /// Complete a held order in Supabase.
  Future<void> retrieveHeldOrder(int orderId) async {
    await _log('retrieveHeldOrder: id=$orderId');
    await _supabase.completeHeldOrder(orderId);
  }

  /// Delete a held order in Supabase.
  Future<void> deleteHeldOrder(int orderId) async {
    await _log('deleteHeldOrder: id=$orderId');
    await _supabase.completeHeldOrder(orderId);
  }
}
