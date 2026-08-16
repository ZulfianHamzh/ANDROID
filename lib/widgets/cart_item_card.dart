import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../utils/app_theme.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final int index;
  final VoidCallback? onRemove;
  final Function(int)? onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.grayBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Nama + harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.darkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rp ${_fmt(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.60),
                      ),
                    ),
                    if (item.isHomeVisit)
                      Text('Home Visit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              // Qty controls
              _qtyBtn(Icons.remove, () {
                if (item.quantity > 1) {
                  onQuantityChanged?.call(item.quantity - 1);
                } else {
                  onRemove?.call();
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              _qtyBtn(Icons.add, () =>
                  onQuantityChanged?.call(item.quantity + 1)),
              const SizedBox(width: 10),
              // Total
              SizedBox(
                width: 84,
                child: Text('Rp ${_fmt(item.totalPrice)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 20, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
