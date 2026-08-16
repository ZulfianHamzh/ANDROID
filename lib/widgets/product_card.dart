import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int? branchId;

  const ProductCard({super.key, required this.product, this.branchId});

  String _fmt(int price) {
    return price
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final clinicPrice = product.getEffectivePriceClinic(branchId ?? 0);
    final homePrice = product.getEffectivePriceHomeVisit(branchId ?? 0);
    final hasHomeVisit = product.priceHomeVisit != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama produk — 2 baris max
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const Spacer(),
            // Harga di tempat (Klinik)
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Rp ${_fmt(clinicPrice)}',
                    style: const TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Harga panggilan (Home Visit)
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasHomeVisit ? 'Rp ${_fmt(homePrice)}' : '—',
                    style: TextStyle(
                      color: hasHomeVisit
                          ? AppColors.orange
                          : Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
