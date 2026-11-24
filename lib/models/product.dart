/// Model Produk & Inventori Toko
class Product {
  final int? id;
  final String name;
  final String? barcode;
  final String? imagePath; // Path gambar produk lokal
  final int costPrice; // Harga Pokok Penjualan (HPP / Modal)
  final int sellingPrice; // Harga Jual ke Pembeli
  final int stock; // Jumlah stok saat ini
  final bool trackStock; // true jika stok dihitung, false jika jasa/makanan tanpa batas stok
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    this.barcode,
    this.imagePath,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    this.trackStock = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Menghitung apakah stok sudah menipis (<= 5)
  bool get isLowStock => trackStock && stock <= 5 && stock > 0;

  /// Menghitung apakah stok sudah habis (<= 0)
  bool get isOutOfStock => trackStock && stock <= 0;

  /// Estimasi keuntungan per unit barang (Harga Jual - HPP)
  int get profitPerUnit => sellingPrice - costPrice;

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? imagePath,
    bool resetImagePath = false,
    int? costPrice,
    int? sellingPrice,
    int? stock,
    bool? trackStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      imagePath: resetImagePath ? null : (imagePath ?? this.imagePath),
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      trackStock: trackStock ?? this.trackStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode?.trim().isEmpty ?? true ? null : barcode?.trim(),
      'image_path': imagePath?.trim().isEmpty ?? true ? null : imagePath?.trim(),
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock': stock,
      'track_stock': trackStock ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      imagePath: map['image_path'] as String?,
      costPrice: map['cost_price'] as int? ?? 0,
      sellingPrice: map['selling_price'] as int? ?? 0,
      stock: map['stock'] as int? ?? 0,
      trackStock: (map['track_stock'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
