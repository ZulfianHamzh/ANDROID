import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? notes;
  final bool isHomeVisit;
  final int? branchId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.notes,
    this.isHomeVisit = false,
    this.branchId,
  });

  int get unitPrice {
    if (branchId != null) {
      return isHomeVisit
          ? product.getEffectivePriceHomeVisit(branchId!)
          : product.getEffectivePriceClinic(branchId!);
    }
    return isHomeVisit
        ? (product.priceHomeVisit ?? product.priceClinic)
        : product.priceClinic;
  }

  int get totalPrice => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product(
        id: json['product_id'] as int,
        name: json['product_name'] as String? ?? '',
        priceClinic: json['unit_price'] as int,
      ),
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
      isHomeVisit: json['is_home_visit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'product_name': product.name,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'notes': notes,
    'is_home_visit': isHomeVisit,
  };
}
