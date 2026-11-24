import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Provider Pengelola Keranjang Belanja Kasir
class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.length;

  /// Total kuantitas seluruh barang dalam keranjang
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Total nominal tagihan (Omzet)
  int get totalAmount =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  /// Total modal HPP seluruh item dalam keranjang
  int get totalCost =>
      _items.values.fold(0, (sum, item) => sum + item.subtotalCost);

  /// Mendapatkan jumlah kuantitas produk yang sudah ada di keranjang
  int getProductQuantity(int? productId) {
    if (productId == null) return 0;
    return _items[productId]?.quantity ?? 0;
  }

  /// Menambahkan barang ke keranjang (+1)
  /// Mengembalikan pesan error jika stok tidak mencukupi
  String? addToCart(Product product) {
    if (product.id == null) return 'Produk tidak valid';

    if (product.trackStock) {
      final currentQtyInCart = _items[product.id]?.quantity ?? 0;
      if (currentQtyInCart >= product.stock) {
        return 'Stok produk "${product.name}" hanya tersisa ${product.stock}';
      }
    }

    if (_items.containsKey(product.id)) {
      _items[product.id!]!.quantity += 1;
    } else {
      _items[product.id!] = CartItem(product: product, quantity: 1);
    }

    notifyListeners();
    return null;
  }

  /// Menambah kuantitas item
  String? incrementQuantity(int productId) {
    if (!_items.containsKey(productId)) return null;

    final item = _items[productId]!;
    if (item.product.trackStock && item.quantity >= item.product.stock) {
      return 'Stok maksimal ${item.product.stock} tercapai';
    }

    item.quantity += 1;
    notifyListeners();
    return null;
  }

  /// Mengurangi kuantitas item (jika 0, hapus dari keranjang)
  void decrementQuantity(int productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity -= 1;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  /// Update kuantitas langsung secara manual
  String? updateQuantity(int productId, int quantity) {
    if (!_items.containsKey(productId)) return null;

    if (quantity <= 0) {
      _items.remove(productId);
      notifyListeners();
      return null;
    }

    final item = _items[productId]!;
    if (item.product.trackStock && quantity > item.product.stock) {
      return 'Stok maksimal ${item.product.stock}';
    }

    item.quantity = quantity;
    notifyListeners();
    return null;
  }

  /// Menghapus produk tertentu dari keranjang
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Mengosongkan seluruh keranjang belanja
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
