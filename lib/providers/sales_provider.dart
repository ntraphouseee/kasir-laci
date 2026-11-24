import 'package:flutter/foundation.dart';
import '../core/database/app_database.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

enum ReportFilter { hariIni, mingguIni, bulanIni }

/// Provider Pengelola Transaksi Penjualan & Laporan Omzet / Laba Untung
class SalesProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Sale> _sales = [];
  Map<String, dynamic> _summary = {
    'transaction_count': 0,
    'total_omzet': 0,
    'total_cost': 0,
    'net_profit': 0,
  };

  ReportFilter _currentFilter = ReportFilter.hariIni;
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> get sales => _sales;
  Map<String, dynamic> get summary => _summary;
  ReportFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalOmzet => _summary['total_omzet'] as int? ?? 0;
  int get totalCost => _summary['total_cost'] as int? ?? 0;
  int get netProfit => _summary['net_profit'] as int? ?? 0;
  int get transactionCount => _summary['transaction_count'] as int? ?? 0;

  /// Memuat riwayat penjualan berdasarkan filter aktif
  Future<void> loadSales([ReportFilter? filter]) async {
    _isLoading = true;
    _errorMessage = null;
    if (filter != null) _currentFilter = filter;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime startDate;
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (_currentFilter) {
        case ReportFilter.hariIni:
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          break;
        case ReportFilter.mingguIni:
          // Awal minggu (Senin)
          final weekday = now.weekday; // 1 = Senin ... 7 = Minggu
          startDate = DateTime(now.year, now.month, now.day - (weekday - 1), 0, 0, 0);
          break;
        case ReportFilter.bulanIni:
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          break;
      }

      _sales = await _db.getSales(startDate: startDate, endDate: endDate);
      _summary = await _db.getSalesSummary(startDate: startDate, endDate: endDate);
    } catch (e) {
      _errorMessage = 'Gagal memuat laporan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Eksekusi checkout transaksi kasir
  Future<Sale> processCheckout({
    required int paidAmount,
    required String paymentMethod,
    required List<CartItem> cartItems,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Keranjang belanja masih kosong!');
    }

    final totalAmount =
        cartItems.fold(0, (sum, item) => sum + item.subtotal);
    final totalCost =
        cartItems.fold(0, (sum, item) => sum + item.subtotalCost);

    // Validasi pembayaran tunai
    if (paymentMethod == 'TUNAI' && paidAmount < totalAmount) {
      throw Exception('Jumlah uang yang dibayarkan kurang!');
    }

    final changeAmount =
        paymentMethod == 'TUNAI' ? (paidAmount - totalAmount) : 0;

    // Nomor faktur berurutan & unik
    final now = DateTime.now();
    final invoiceNumber =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final saleItems = cartItems.map((c) {
      return SaleItem(
        productId: c.product.id ?? 0,
        productName: c.product.name,
        costPrice: c.product.costPrice,
        sellingPrice: c.product.sellingPrice,
        quantity: c.quantity,
        subtotal: c.subtotal,
      );
    }).toList();

    final sale = Sale(
      invoiceNumber: invoiceNumber,
      totalAmount: totalAmount,
      totalCost: totalCost,
      paymentMethod: paymentMethod,
      paidAmount: paymentMethod == 'QRIS' ? totalAmount : paidAmount,
      changeAmount: changeAmount,
      createdAt: now,
      items: saleItems,
    );

    // Jalankan transaksi ACID di database
    final saleId = await _db.executeCheckoutTransaction(
      sale: sale,
      cartItems: cartItems,
    );

    final completedSale = Sale(
      id: saleId,
      invoiceNumber: sale.invoiceNumber,
      totalAmount: sale.totalAmount,
      totalCost: sale.totalCost,
      paymentMethod: sale.paymentMethod,
      paidAmount: sale.paidAmount,
      changeAmount: sale.changeAmount,
      createdAt: sale.createdAt,
      items: saleItems,
    );

    // Perbarui riwayat penjualan aktif
    await loadSales();

    return completedSale;
  }
}
