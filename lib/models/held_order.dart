import 'cart_item.dart';

class HeldOrder {
  final int id;
  final List<CartItem> items;
  final String? notes;

  /// Multiple customer names (JSONB `customers`).
  final List<String> customerNames;

  final String status;
  final DateTime createdAt;

  HeldOrder({
    required this.id,
    required this.items,
    this.notes,
    List<String>? customerNames,
    String? customerName,
    this.status = 'active',
    required this.createdAt,
  }) : customerNames = (customerNames != null && customerNames.isNotEmpty)
            ? customerNames
            : (customerName != null && customerName.trim().isNotEmpty
                ? [customerName.trim()]
                : const <String>[]);

  /// Backward-compatible getter (all names joined).
  String? get customerName => customerNames.isEmpty ? null : customerNames.join(', ');

  bool get isActive => status == 'active';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  factory HeldOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final customerNames = <String>[];
    for (final c in (json['customers'] as List<dynamic>?) ?? const []) {
      final s = c.toString().trim();
      if (s.isNotEmpty && !customerNames.contains(s)) customerNames.add(s);
    }
    return HeldOrder(
      id: json['id'] as int,
      items: itemsRaw.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList(),
      notes: json['notes'] as String?,
      customerNames: customerNames.isNotEmpty ? customerNames : null,
      customerName: json['customer_name'] as String?,
      status: json['hold_order_status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
