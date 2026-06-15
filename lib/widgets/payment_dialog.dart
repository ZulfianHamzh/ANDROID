import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final int totalAmount;
  final VoidCallback? onDismiss;
  final String? initialCustomerName;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.onDismiss,
    this.initialCustomerName,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  late final TextEditingController _customerController;
  final _formKey = GlobalKey<FormState>();
  int _change = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: widget.initialCustomerName ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final paid = int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _change = paid - widget.totalAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pembayaran', style: AppTypography.headingBold),
                    GestureDetector(
                      onTap: () {
                        widget.onDismiss?.call();
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Total: Rp ${_formatPrice(widget.totalAmount)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 12),
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentMethod.values.map((method) {
                    final isSelected = _selectedMethod == method;
                    return ChoiceChip(
                      label: Text(method.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMethod = method);
                      },
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                if (_selectedMethod == PaymentMethod.cash) ...[
                  const SizedBox(height: 12),
                  const Text('Jumlah Dibayar', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => _calculateChange(),
                  ),
                  if (_change >= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Kembalian: Rp ${_formatPrice(_change)}',
                        style: TextStyle(
                          color: _change >= 0 ? AppColors.primaryGreen : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const Text('Nama Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _customerController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama pelanggan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pelanggan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submitted
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _submitted = true);
                            final paid = int.tryParse(_amountController.text.replaceAll('.', '')) ?? widget.totalAmount;
                            if (_selectedMethod == PaymentMethod.cash && paid < widget.totalAmount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Jumlah pembayaran tidak mencukupi')),
                              );
                              setState(() => _submitted = false);
                              return;
                            }
                            Navigator.pop(context, {
                              'amountPaid': _selectedMethod == PaymentMethod.cash ? paid : widget.totalAmount,
                              'paymentMethod': _selectedMethod,
                              'customerName': _customerController.text.trim(),
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
}
