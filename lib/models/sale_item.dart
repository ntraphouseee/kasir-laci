/// Rincian Item pada Transaksi Penjualan
class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final int costPrice;
  final int sellingPrice;
  final int quantity;
  final int subtotal;

  SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.subtotal,
  });

  int get subtotalCost => costPrice * quantity;
  int get subtotalProfit => subtotal - subtotalCost;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name'] as String? ?? '',
      costPrice: map['cost_price'] as int? ?? 0,
      sellingPrice: map['selling_price'] as int? ?? 0,
      quantity: map['quantity'] as int? ?? 0,
      subtotal: map['subtotal'] as int? ?? 0,
    );
  }
}
