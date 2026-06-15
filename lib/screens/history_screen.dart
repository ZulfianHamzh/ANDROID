import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/pos_provider.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../widgets/skeleton_widget.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveUtils.init(context);
    final posState = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final transactions = posState.transactions.reversed.toList();
    final currencyFormat = NumberFormat.decimalPattern('id');
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    final supabaseService = ref.read(supabaseServiceProvider);
    final cashierId = posState.currentUser?.id ?? '';

    return RefreshIndicator(
      onRefresh: () => notifier.loadProducts(),
      color: AppColors.primaryGreen,
      child: _buildContent(posState, transactions, notifier, currencyFormat, dateFormat, supabaseService, cashierId),
    );
  }

  Widget _buildContent(PosState posState, List<Transaction> transactions, PosProvider notifier,
      NumberFormat currencyFormat, DateFormat dateFormat,
      SupabaseService supabaseService, String cashierId) {
    if (posState.isLoading) {
      return const SkeletonHistoryList();
    }

    if (transactions.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 100),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: ResponsiveUtils.icon2XLarge, color: Colors.grey[300]),
                SizedBox(height: ResponsiveUtils.spaceNormal),
                Text('Belum ada transaksi',
                  style: TextStyle(color: Colors.grey[500], fontSize: ResponsiveUtils.fontLarge),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: ResponsiveUtils.paddingNormal,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _TransactionCard(
          transaction: transaction,
          currencyFormat: currencyFormat,
          dateFormat: dateFormat,
          supabaseService: supabaseService,
          cashierId: cashierId,
          onRefund: () => notifier.loadProducts(),
        );
      },
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final SupabaseService supabaseService;
  final String cashierId;
  final VoidCallback? onRefund;

  const _TransactionCard({
    required this.transaction,
    required this.currencyFormat,
    required this.dateFormat,
    required this.supabaseService,
    required this.cashierId,
    this.onRefund,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: _buildStatusIcon(t.status),
            title: Text('#${t.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${widget.dateFormat.format(t.createdAt)} - ${t.cashierName}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.printStatus == PrintStatus.printed)
                      const Icon(Icons.print, size: 12, color: Colors.green),
                    if (t.printStatus == PrintStatus.unprinted || t.printStatus == PrintStatus.failed)
                      Icon(Icons.print_disabled, size: 12,
                        color: t.printStatus == PrintStatus.failed ? Colors.orange : Colors.grey,
                      ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text('Rp ${widget.currencyFormat.format(t.totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkBlue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(t.paymentMethod.displayName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (t.customerName != null)
                    Text('Pelanggan: ${t.customerName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.darkBlue),
                    ),
                  const SizedBox(height: 8),
                  ...t.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.product.name}${item.isHomeVisit ? " (Home Visit)" : ""}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text('${item.quantity}x',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text('Rp ${widget.currencyFormat.format(item.totalPrice)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${t.status.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(t.status),
                        ),
                      ),
                      if (t.paymentMethod == PaymentMethod.cash) ...[
                        Text('Bayar: Rp ${widget.currencyFormat.format(t.amountPaid)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text('Kembali: Rp ${widget.currencyFormat.format(t.change)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),                  // Print status row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          t.printStatus == PrintStatus.printed ? Icons.check_circle : 
                          t.printStatus == PrintStatus.failed ? Icons.error : Icons.schedule,
                          size: 14,
                          color: t.printStatus == PrintStatus.printed ? Colors.green : 
                                 t.printStatus == PrintStatus.failed ? Colors.orange : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text('Print: ${t.printStatus.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: t.printStatus == PrintStatus.printed ? Colors.green : 
                                   t.printStatus == PrintStatus.failed ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (t.status == TransactionStatus.completed) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRefundDialog(t),
                        icon: const Icon(Icons.replay, size: 16, color: Colors.white),
                        label: const Text('Refund', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    // Print Again / Make Copy button
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final isPrinted = t.printStatus == PrintStatus.printed;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await ref.read(posProvider.notifier).printTransaction(t);
                              if (success && widget.onRefund != null) {
                                widget.onRefund!();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                        ? (isPrinted ? 'Copy printed successfully' : 'Print success')
                                        : 'Print failed - printer not connected',
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              isPrinted ? Icons.copy : Icons.print,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              isPrinted ? 'Make a Copy' : 'Print Again',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPrinted
                                  ? AppColors.darkBlue
                                  : AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRefundDialog(Transaction transaction) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${transaction.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Total: Rp ${widget.currencyFormat.format(transaction.totalAmount)}',
                style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan Refund',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan alasan refund...',
                ),
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
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Alasan refund wajib diisi')),
                  );
                }
                return;
              }
              try {
                await widget.supabaseService.processRefund(
                  transactionId: int.tryParse(transaction.id) ?? 0,
                  reason: reason,
                  refundAmount: transaction.totalAmount,
                  cashierId: widget.cashierId,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                widget.onRefund?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refund berhasil diproses')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(TransactionStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case TransactionStatus.completed:
        icon = Icons.check_circle;
        color = AppColors.primaryGreen;
      case TransactionStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
      case TransactionStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
      case TransactionStatus.refunded:
        icon = Icons.replay;
        color = Colors.blueGrey;
    }
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.primaryGreen;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.refunded:
        return Colors.blueGrey;
    }
  }
}
