import 'cart_item.dart';

enum TransactionStatus { completed, pending, cancelled, refunded }

enum PaymentMethod { cash, debit, credit, qris, eWallet }

enum PrintStatus { printed, unprinted, failed, pending }

extension PrintStatusExtension on PrintStatus {
  String get displayName {
    switch (this) {
      case PrintStatus.printed:
        return 'Printed';
      case PrintStatus.unprinted:
        return 'Unprinted';
      case PrintStatus.failed:
        return 'Failed';
      case PrintStatus.pending:
        return 'Pending';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.debit:
        return 'Debit';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
    }
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }
}

class Transaction {
  final String id;
  final int? orderNo;
  final String cashierId;
  final List<CartItem> items;
  final int totalAmount;
  final int amountPaid;
  final int change;
  final PaymentMethod paymentMethod;
  final String cashierName;
  final String? customerName;
  final int? branchId;
  final String? branchName;
  final DateTime createdAt;
  final TransactionStatus status;
  final PrintStatus printStatus;

  Transaction({
    required this.id,
    this.orderNo,
    required this.cashierId,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.cashierName,
    this.customerName,
    this.branchId,
    this.branchName,
    required this.createdAt,
    this.status = TransactionStatus.completed,
    this.printStatus = PrintStatus.unprinted,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_no': orderNo,
    'cashier_id': cashierId,
    'items': items.map((e) => e.toJson()).toList(),
    'total_amount': totalAmount,
    'amount_paid': amountPaid,
    'change': change,
    'payment_method': paymentMethod.name,
    'cashier_name': cashierName,
    'customer_name': customerName,
    'branch_id': branchId,
    'branch_name': branchName,
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'print_status': printStatus.name,
  };
}
