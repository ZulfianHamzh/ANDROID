import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../providers/pos_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton_widget.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    // 800px → tablet layout; <800 → phone
    final isTablet = MediaQuery.of(context).size.width >= 700;
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    return isTablet
        ? _buildTabletLayout(posState, notifier)
        : _buildPhoneLayout(posState, notifier);
  }

  // ── PHONE ─────────────────────────────────────────────────────────────
  Widget _buildPhoneLayout(PosState posState, PosProvider notifier) {
    final currencyFormat = NumberFormat.decimalPattern('id');
    final products = notifier.filteredProducts(false);
    final categories = notifier.categories;

    if (posState.isLoading) {
      return Column(children: [
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildCategoryChips(posState, categories),
        const SizedBox(height: 6),
        const Expanded(child: SkeletonProductGrid(crossAxisCount: 2)),
        _buildCartFooter(posState, notifier, currencyFormat),
      ]);
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadProducts(),
      color: AppColors.primaryGreen,
      child: Column(children: [
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildCategoryChips(posState, categories),
        const SizedBox(height: 6),
        Expanded(child: _buildProductGrid(products, crossAxisCount: 2)),
        _buildCartFooter(posState, notifier, currencyFormat),
      ]),
    );
  }

  // ── TABLET ────────────────────────────────────────────────────────────
  Widget _buildTabletLayout(PosState posState, PosProvider notifier) {
    final products = notifier.filteredProducts(false);
    final categories = notifier.categories;

    if (posState.isLoading) {
      return Row(children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildCategoryChips(posState, categories),
              ),
              const SizedBox(height: 6),
              const Expanded(
                  child: SkeletonProductGrid(crossAxisCount: 3, itemCount: 9)),
            ],
          ),
        ),
        const SkeletonCartPanel(),
      ]);
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadProducts(),
      color: AppColors.primaryGreen,
      child: Row(children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildCategoryChips(posState, categories),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildProductGrid(products, crossAxisCount: 3)),
          ],
        ),
      ),
      _buildCartPanel(posState, notifier),
    ]),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final posState = ref.watch(posProvider);
    final heldCount = posState.heldOrders.length;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(posProvider.notifier).setSearchQuery(v),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppColors.searchHint, size: 18),
                hintText: 'Cari layanan...',
                hintStyle: TextStyle(color: AppColors.searchHint, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        if (heldCount > 0) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showHeldOrders(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$heldCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── CATEGORY CHIPS ────────────────────────────────────────────────────
  Widget _buildCategoryChips(PosState posState, List<String> categories) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('Semua', posState.selectedCategory.isEmpty),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildChip(cat, posState.selectedCategory == cat),
          )),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => ref
          .read(posProvider.notifier)
          .setSelectedCategory(label == 'Semua' ? '' : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── PRODUCT GRID ──────────────────────────────────────────────────────
  Widget _buildProductGrid(List<Product> products,
      {required int crossAxisCount}) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // Sedikit lebih tinggi agar gambar + teks proporsional
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCardWithPrice(
          product: products[index],
          onTap: (isHomeVisit) =>
              ref.read(posProvider.notifier).addToCart(products[index],
                  isHomeVisit: isHomeVisit),
        );
      },
    );
  }

  // ── CART PANEL (tablet) ───────────────────────────────────────────────
  Widget _buildCartPanel(PosState posState, PosProvider notifier) {
    final cartItems = posState.cartItems;
    final total = notifier.cartTotal;
    final itemCount = notifier.cartItemCount;
    final currencyFormat = NumberFormat.decimalPattern('id');
    // Lebar panel dikecilkan sedikit: maks 320 (dr 435)
    final cartWidth =
        (ResponsiveUtils.screenWidth * 0.40).clamp(260.0, 320.0);

    return Container(
      width: cartWidth,
      color: Colors.white.withValues(alpha: 0.95),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_cart,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('Keranjang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const Spacer(),
                if (cartItems.isNotEmpty)
                  Text('No. ${posState.transactions.length + 1}',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.40),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grayDivider),
          // List
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Text('Pilih menu...',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.35),
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) => CartItemCard(
                      item: cartItems[index],
                      index: index,
                      onRemove: () => notifier.removeFromCart(index),
                      onQuantityChanged: (qty) =>
                          notifier.updateCartItemQuantity(index, qty),
                    ),
                  ),
          ),
          const Divider(height: 1, color: AppColors.grayDivider),
          // Checkout bar — lebih kompak: h=72
          Container(
            height: 72,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$itemCount items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Rp ${currencyFormat.format(total)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed:
                      total > 0 ? () => _showPaymentDialog(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(72, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Bayar',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed:
                      total > 0 ? () => _holdOrder(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(56, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  child: const Text('Hold',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CART FOOTER (phone) ───────────────────────────────────────────────
  Widget _buildCartFooter(PosState posState, PosProvider notifier,
      NumberFormat currencyFormat) {
    final total = notifier.cartTotal;
    final itemCount = notifier.cartItemCount;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$itemCount items',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w600),
                ),
                Text('Rp ${currencyFormat.format(total)}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (total > 0)
            IconButton(
              onPressed: () => _holdOrder(context),
              icon: const Icon(Icons.pause_circle,
                  color: AppColors.orange, size: 22),
              tooltip: 'Hold Order',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: total > 0 ? () => _showPaymentDialog(context) : null,
            icon: const Icon(Icons.shopping_cart_checkout,
                color: Colors.white, size: 16),
            label: const Text('Bayar',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  // ── DIALOGS ───────────────────────────────────────────────────────────
  Future<void> _showPaymentDialog(BuildContext context) async {
    final posState = ref.read(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => PaymentDialog(
        totalAmount: notifier.cartTotal,
        initialCustomerName: posState.pendingCustomerName,
        onDismiss: () {},
      ),
    );
    if (result != null && context.mounted) {
      notifier.completeTransaction(
        amountPaid: result['amountPaid'] as int,
        paymentMethod: result['paymentMethod'] as PaymentMethod,
        customerName: result['customerName'] as String?,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil!')),
      );
    }
  }

  void _holdOrder(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold Order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pesanan akan ditahan dan bisa diambil kembali nanti.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Nama pelanggan wajib diisi'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              ref.read(posProvider.notifier).holdCurrentOrder(
                customerName: nameController.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesanan ditahan')),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange),
            child: const Text('Hold',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHeldOrders(BuildContext context) {
    final posState = ref.read(posProvider);
    final heldOrders = posState.heldOrders;
    final currencyFormat = NumberFormat.decimalPattern('id');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pesanan Ditahan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Text('${heldOrders.length} pesanan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Divider(),
              Expanded(
                child: heldOrders.isEmpty
                    ? Center(child: Text('Tidak ada pesanan ditahan',
                        style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: heldOrders.length,
                        itemBuilder: (context, index) {
                          final order = heldOrders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              dense: true,
                              leading: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.pause_circle,
                                    color: AppColors.orange, size: 18),
                              ),
                              title: Text(
                                '${order.customerName ?? "Tanpa nama"} — ${order.totalItems} items',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text(
                                'Rp ${currencyFormat.format(order.totalAmount)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.shopping_cart,
                                        color: AppColors.primaryGreen, size: 18),
                                    tooltip: 'Ambil pesanan',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref
                                          .read(posProvider.notifier)
                                          .retrieveHeldOrder(index);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Pesanan diambil')),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => ref
                                        .read(posProvider.notifier)
                                        .deleteHeldOrder(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product card wrapper ───────────────────────────────────────────────
class _ProductCardWithPrice extends StatelessWidget {
  final Product product;
  final void Function(bool isHomeVisit) onTap;

  const _ProductCardWithPrice(
      {required this.product, required this.onTap});

  bool get _hasHomeVisit => product.priceHomeVisit != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _hasHomeVisit ? _showPriceOptions(context) : onTap(false),
      child: ProductCard(product: product),
    );
  }

  void _showPriceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.darkBlue),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(ctx); onTap(false); },
                icon: const Icon(Icons.store, color: Colors.white, size: 16),
                label: Text(
                  'Di Tempat — Rp ${_fmt(product.priceClinic)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (_hasHomeVisit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); onTap(true); },
                  icon: const Icon(Icons.home, color: Colors.white, size: 16),
                  label: Text(
                    'Home Visit — Rp ${_fmt(product.priceHomeVisit!)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
