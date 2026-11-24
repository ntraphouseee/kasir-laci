import 'product.dart';

/// Item dalam Keranjang Belanja Kasir
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  int get subtotal => product.sellingPrice * quantity;
  int get subtotalCost => product.costPrice * quantity;
  int get subtotalProfit => subtotal - subtotalCost;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
