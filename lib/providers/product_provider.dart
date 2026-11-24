import 'package:flutter/foundation.dart';
import '../core/database/app_database.dart';
import '../models/product.dart';

/// Provider Pengelola Produk & Stok Inventori
class ProductProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  /// Jumlah produk dengan stok menipis (<= 5)
  int get lowStockCount =>
      _products.where((p) => p.isLowStock || p.isOutOfStock).length;

  Future<void> loadProducts({String? query}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchQuery = query ?? _searchQuery;
      _products = await _db.getAllProducts(query: _searchQuery);
    } catch (e) {
      _errorMessage = 'Gagal memuat produk: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProducts(query: query);
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _db.insertProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah produk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _db.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui produk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _db.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus produk: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Product?> findByBarcode(String barcode) async {
    try {
      return await _db.getProductByBarcode(barcode);
    } catch (e) {
      return null;
    }
  }

  Future<void> seedSampleData() async {
    try {
      await _db.seedSampleProducts();
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Gagal memasukkan data contoh: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllProducts() async {
    try {
      await _db.clearAllProducts();
      await loadProducts();
    } catch (e) {
      _errorMessage = 'Gagal mengosongkan produk: $e';
      notifyListeners();
    }
  }
}
