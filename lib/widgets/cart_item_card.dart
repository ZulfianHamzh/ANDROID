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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Rp ${_fmt(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withValues(alpha: 0.60),
                      ),
                    ),
                    if (item.isHomeVisit)
                      Text('Home Visit',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              _qtyBtn(Icons.add, () =>
                  onQuantityChanged?.call(item.quantity + 1)),
              const SizedBox(width: 6),
              // Total
              SizedBox(
                width: 62,
                child: Text('Rp ${_fmt(item.totalPrice)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 16, color: Colors.red),
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
        width: 22, height: 22,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
