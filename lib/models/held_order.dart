import 'cart_item.dart';

class HeldOrder {
  final int id;
  final List<CartItem> items;
  final String? notes;
  final String? customerName;
  final String status;
  final DateTime createdAt;

  HeldOrder({
    required this.id,
    required this.items,
    this.notes,
    this.customerName,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isActive => status == 'active';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  factory HeldOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    return HeldOrder(
      id: json['id'] as int,
      items: itemsRaw.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
      notes: json['notes'] as String?,
      customerName: json['customer_name'] as String?,
      status: json['hold_order_status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
