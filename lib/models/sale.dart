import 'sale_item.dart';

/// Model Transaksi Penjualan
class Sale {
  final int? id;
  final String invoiceNumber;
  final int totalAmount; // Total Omzet
  final int totalCost; // Total HPP Modal
  final String paymentMethod; // 'TUNAI' atau 'QRIS'
  final int paidAmount; // Uang yang diserahkan pembeli
  final int changeAmount; // Uang kembalian
  final DateTime createdAt;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.totalCost,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Keuntungan bersih transaksi (Omzet - HPP Modal)
  int get netProfit => totalAmount - totalCost;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'total_amount': totalAmount,
      'total_cost': totalCost,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem> items = const []}) {
    return Sale(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      totalAmount: map['total_amount'] as int? ?? 0,
      totalCost: map['total_cost'] as int? ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'TUNAI',
      paidAmount: map['paid_amount'] as int? ?? 0,
      changeAmount: map['change_amount'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: items,
    );
  }
}
