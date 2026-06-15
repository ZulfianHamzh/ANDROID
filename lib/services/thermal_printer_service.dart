import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import 'bluetooth_service.dart';

class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();

  factory ThermalPrinterService() {
    return _instance;
  }

  ThermalPrinterService._internal();

  final BluetoothService _bluetooth = BluetoothService();

  /// ESC/POS commands
  static const List<int> _initPrinter = [0x1B, 0x40];  // ESC @
  static const List<int> _centerAlign = [0x1B, 0x61, 0x01];  // ESC a 1
  static const List<int> _leftAlign = [0x1B, 0x61, 0x00];  // ESC a 0
  static const List<int> _bold = [0x1B, 0x45, 0x01];  // ESC E 1
  static const List<int> _unbold = [0x1B, 0x45, 0x00];  // ESC E 0
  static const List<int> _largeFontOn = [0x1B, 0x21, 0x08];  // ESC ! 8
  static const List<int> _largeFontOff = [0x1B, 0x21, 0x00];  // ESC ! 0
  static const List<int> _lineFeed = [0x0A];  // LF
  static const List<int> _cutPaper = [0x1D, 0x56, 0x42, 0x00];  // GS V B 0

  /// Print transaction receipt
  Future<bool> printTransaction(Transaction transaction) async {
    try {
      if (!_bluetooth.isConnected) {
        debugPrint('[Printer] Not connected to printer');
        return false;
      }

      final receiptData = _generateReceipt(transaction);
      final result = await _bluetooth.sendData(receiptData);

      if (result) {
        debugPrint('[Printer] ✓ Receipt printed successfully');
      } else {
        debugPrint('[Printer] ✗ Failed to print receipt');
      }

      return result;
    } catch (e) {
      debugPrint('[Printer] Print error: $e');
      return false;
    }
  }

  /// Generate receipt data in ESC/POS format
  List<int> _generateReceipt(Transaction transaction) {
    final receipt = <int>[];

    // Initialize printer
    receipt.addAll(_initPrinter);
    receipt.addAll(_lineFeed);

    // Header - centered and bold
    receipt.addAll(_centerAlign);
    receipt.addAll(_bold);
    receipt.addAll(_largeFontOn);
    receipt.addAll(_stringToBytes('DHBH POS'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_largeFontOff);
    
    // Branch name
    if (transaction.branchName != null && transaction.branchName!.isNotEmpty) {
      receipt.addAll(_stringToBytes(transaction.branchName!));
      receipt.addAll(_lineFeed);
    }
    receipt.addAll(_lineFeed);

    // Cashier and date
    receipt.addAll(_leftAlign);
    receipt.addAll(_unbold);
    receipt.addAll(_largeFontOff);
    receipt.addAll(_stringToBytes('Kasir: ${transaction.cashierName}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Tgl: ${_formatDateTime(transaction.createdAt)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('ID: ${transaction.id}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Divider
    receipt.addAll(_stringToBytes('─' * 32));
    receipt.addAll(_lineFeed);

    // Items header
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('Item'));
    receipt.addAll(_stringToBytes(' ' * 10)); // Spacing
    receipt.addAll(_stringToBytes('Qty'));
    receipt.addAll(_stringToBytes(' ' * 5));
    receipt.addAll(_stringToBytes('Harga'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_lineFeed);

    // Items
    for (var item in transaction.items) {
      final itemName = item.product.name.length > 20
          ? item.product.name.substring(0, 20)
          : item.product.name;
      receipt.addAll(_stringToBytes(itemName));
      receipt.addAll(_lineFeed);

      // Price type label (Clinic / Home Visit)
      final priceType = item.isHomeVisit ? '(Home Visit)' : '(Klinik)';
      final unitPriceStr = _formatCurrency(item.unitPrice);
      receipt.addAll(_stringToBytes('  $priceType @$unitPriceStr'));
      receipt.addAll(_lineFeed);

      final qtyStr = 'x${item.quantity}';
      final priceStr = _formatCurrency(item.totalPrice);
      final spacing = ' ' * (32 - qtyStr.length - priceStr.length);
      receipt.addAll(_stringToBytes('$qtyStr$spacing$priceStr'));
      receipt.addAll(_lineFeed);
      receipt.addAll(_lineFeed);
    }

    // Divider
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('─' * 32));
    receipt.addAll(_lineFeed);

    // Total
    receipt.addAll(_bold);
    receipt.addAll(_largeFontOn);
    final totalStr = _formatCurrency(transaction.totalAmount);
    final totalLine = 'Total: $totalStr';
    receipt.addAll(_centerAlign);
    receipt.addAll(_stringToBytes(totalLine));
    receipt.addAll(_lineFeed);
    receipt.addAll(_largeFontOff);
    receipt.addAll(_unbold);
    receipt.addAll(_lineFeed);

    // Payment method
    receipt.addAll(_leftAlign);
    receipt.addAll(_stringToBytes('Metode: ${transaction.paymentMethod.displayName}'));
    receipt.addAll(_lineFeed);

    // Customer info if available
    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) {
      receipt.addAll(_stringToBytes('Pelanggan: ${transaction.customerName}'));
      receipt.addAll(_lineFeed);
    }

    // Footer
    receipt.addAll(_lineFeed);
    receipt.addAll(_centerAlign);
    receipt.addAll(_stringToBytes('Terima kasih!'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Selamat datang kembali'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Cut paper
    receipt.addAll(_cutPaper);

    return receipt;
  }

  /// Generate closing report receipt
  List<int> generateClosingReport({
    required String branchName,
    required String cashierName,
    required DateTime waktuBuka,
    required DateTime waktuTutup,
    required int modalAwal,
    required List<Map<String, dynamic>> productsSold,
    required List<Map<String, dynamic>> payments,
    required int totalPenerimaan,
    required int totalTransaksiSelesai,
    required int totalTransaksiHold,
  }) {
    final receipt = <int>[];

    receipt.addAll(_initPrinter);
    receipt.addAll(_lineFeed);

    // Title
    receipt.addAll(_centerAlign);
    receipt.addAll(_bold);
    receipt.addAll(_largeFontOn);
    receipt.addAll(_stringToBytes('LAPORAN TUTUP KASIR'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_largeFontOff);
    receipt.addAll(_stringToBytes('PENJUALAN & TRANSAKSI DHBH'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Info
    receipt.addAll(_leftAlign);
    receipt.addAll(_stringToBytes('Cabang: $branchName'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Kasir: $cashierName'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Waktu Buka: ${_formatDateTime(waktuBuka)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Waktu Tutup: ${_formatDateTime(waktuTutup)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Produk Terjual
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('PRODUK TERJUAL'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_stringToBytes('${'Nama'.padRight(18)} Qty  Harga'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('${'─' * 18} ${'─' * 3} ${'─' * 8}'));
    receipt.addAll(_lineFeed);

    for (final product in productsSold) {
      final name = (product['name'] as String? ?? '').padRight(18);
      final qty = (product['qty'] as int? ?? 0).toString().padLeft(3);
      final price = _formatCurrency(product['total'] as int? ?? 0).padLeft(8);
      receipt.addAll(_stringToBytes('$name $qty $price'));
      receipt.addAll(_lineFeed);
    }

    receipt.addAll(_stringToBytes('${'─' * 32}'));
    receipt.addAll(_lineFeed);

    // Total produk
    final totalQty = productsSold.fold(0, (sum, p) => sum + (p['qty'] as int? ?? 0));
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('Total: ${_formatCurrency(totalPenerimaan)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_lineFeed);

    // Modal Awal
    receipt.addAll(_stringToBytes('${'─' * 32}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Modal Awal: ${_formatCurrency(modalAwal)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Penerimaan per metode
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('PENERIMAAN'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    for (final payment in payments) {
      final method = (payment['method'] as String? ?? '').padRight(12);
      final amount = _formatCurrency(payment['amount'] as int? ?? 0).padLeft(12);
      receipt.addAll(_stringToBytes('$method$amount'));
      receipt.addAll(_lineFeed);
    }

    receipt.addAll(_stringToBytes('${'─' * 32}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('Total Penerimaan: ${_formatCurrency(totalPenerimaan)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_lineFeed);

    // Saldo Akhir
    receipt.addAll(_stringToBytes('${'─' * 32}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_bold);
    receipt.addAll(_stringToBytes('Saldo Akhir: ${_formatCurrency(modalAwal + totalPenerimaan)}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_unbold);
    receipt.addAll(_lineFeed);

    // Ringkasan transaksi
    receipt.addAll(_stringToBytes('Transaksi Selesai: $totalTransaksiSelesai'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Transaksi Hold: $totalTransaksiHold'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Total Item Terjual: $totalQty'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    // Footer
    receipt.addAll(_centerAlign);
    receipt.addAll(_stringToBytes('${'─' * 32}'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_stringToBytes('Terima kasih'));
    receipt.addAll(_lineFeed);
    receipt.addAll(_lineFeed);

    receipt.addAll(_cutPaper);
    return receipt;
  }

  /// Print closing report
  Future<bool> printClosingReport({
    required String branchName,
    required String cashierName,
    required DateTime waktuBuka,
    required DateTime waktuTutup,
    required int modalAwal,
    required List<Map<String, dynamic>> productsSold,
    required List<Map<String, dynamic>> payments,
    required int totalPenerimaan,
    required int totalTransaksiSelesai,
    required int totalTransaksiHold,
  }) async {
    try {
      if (!_bluetooth.isConnected) {
        debugPrint('[Printer] Not connected');
        return false;
      }

      final data = generateClosingReport(
        branchName: branchName,
        cashierName: cashierName,
        waktuBuka: waktuBuka,
        waktuTutup: waktuTutup,
        modalAwal: modalAwal,
        productsSold: productsSold,
        payments: payments,
        totalPenerimaan: totalPenerimaan,
        totalTransaksiSelesai: totalTransaksiSelesai,
        totalTransaksiHold: totalTransaksiHold,
      );

      final result = await _bluetooth.sendData(data);
      debugPrint('[Printer] Closing report: ${result ? "✓" : "✗"}');
      return result;
    } catch (e) {
      debugPrint('[Printer] Closing report error: $e');
      return false;
    }
  }

  /// Convert string to bytes (ASCII)
  List<int> _stringToBytes(String text) {
    return text.codeUnits;
  }

  /// Format date time
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format currency
  String _formatCurrency(int amount) {
    final formatter = amount.toString();
    if (formatter.length <= 3) return 'Rp$formatter';

    final reversed = formatter.split('').reversed.toList();
    final chunks = <String>[];
    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.sublist(i, i + 3 < reversed.length ? i + 3 : reversed.length).reversed.join());
    }
    return 'Rp${chunks.reversed.join('.')}';
  }
}
