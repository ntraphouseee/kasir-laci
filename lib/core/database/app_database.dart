import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../models/store_profile.dart';

/// Pengelola Database SQLite Lokal 100% Offline-First
/// Menggunakan raw SQL berindeks dan ACID db.transaction()
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  /// Mendapatkan instance database SQLite
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir_umkm.db');
    return _database!;
  }

  /// Inisialisasi file database SQLite
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  /// Migrasi Database
  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrasi ke v2: Menambahkan kolom image_path pada tabel products
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT;');
    }
  }

  /// Membuat tabel dan indeks
  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Produk & Stok
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        image_path TEXT,
        cost_price INTEGER NOT NULL DEFAULT 0,
        selling_price INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        track_stock INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode);');
    await db.execute('CREATE INDEX idx_products_name ON products(name);');

    // 2. Tabel Transaksi Penjualan
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        total_cost INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        paid_amount INTEGER NOT NULL,
        change_amount INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_created_at ON sales(created_at);');

    // 3. Tabel Detail Item Penjualan
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        cost_price INTEGER NOT NULL,
        selling_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);');

    // 4. Tabel Pengaturan Toko & Hardware
    await db.execute('''
      CREATE TABLE store_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Seed Data Pengaturan Default
    await _seedDefaultSettings(db);

    // Pre-seed 5 produk warung contoh saat pertama kali buat DB
    await seedSampleProducts(db);
  }

  /// Seed pengaturan awal toko
  Future<void> _seedDefaultSettings(DatabaseExecutor db) async {
    final defaultSettings = {
      'store_name': 'Kasir Laci',
      'store_address': 'Jl. Pasar Baru No. 12, Indonesia',
      'store_phone': '0812-3456-7890',
      'receipt_footer': 'Terima kasih telah berbelanja!\nBarang yang sudah dibeli tidak dapat ditukar.',
      'qris_image_path': '',
      'printer_mac': '',
      'printer_name': '',
    };

    for (final entry in defaultSettings.entries) {
      await db.insert(
        'store_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Pre-seed 1 produk contoh realistis warung Indonesia lengkap dengan gambar
  Future<void> seedSampleProducts([DatabaseExecutor? dbExecutor]) async {
    final db = dbExecutor ?? await database;
    final now = DateTime.now().toIso8601String();

    String? sampleImagePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final sampleFile = File(p.join(imagesDir.path, 'sample_beras.png'));
      if (!await sampleFile.exists()) {
        const base64Png =
            'iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0N1AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAK5QTFRFAAAAAU6KAVebKbb2VMX4Kbb2VMX4AVaaAVebKbb2RsD3VMX4VMX4AVaZAVebGHalKbb2VMX4Pa7jADJZADhkAStLATBTAT5uAT5vAUd/AUmCAUyHAU6KAU6LAU6MAVGRAVKSAVKTAVOUAVWXAVWYAVaYAVaaAVeaAVebAjtnAkBwAkN2AkmAA02GA0+KA1CLFmiQF2+ZGXimGn6wG4O2G4a6HIe8Kbb2RL/3VMX47aEaPQAAABN0Uk5TABAQEBBQUGBgYGBggM/Pz8/P3xkQ5PoAAADpSURBVFjD7czXDoJAEEBRVOy9YO+KjB0r+v8/ZoQIC0sizq4PxrmvNzmKQklMrd758uSQQw455JBDDjnvnFSBL4Vw8iGzqn7TCYUwTpiEc3gJ6wQlvOOXXCf3ucNKrpO1bp87nsQ4FidFcF6SzwlKkRxHCjh+KaLzlDiHlSI7TJ7jSaLOSxJ3HEmG85QwTtLiqyEcJVHhnOs+rciQLjsdMhKk83ZmgATptBnrCxCXjuvB1IYEpcOyM5zMbEhIMvtTn+sAwhKplZv9aYGgKBkao3uHNhwUnk1gmAoKVYEkCPFSyT9qvSvPQCNJCMEO265wAAAAABJRU5ErkJggg==';
        await sampleFile.writeAsBytes(base64Decode(base64Png));
      }
      sampleImagePath = sampleFile.path;
    } catch (_) {
      sampleImagePath = null;
    }

    final sample = {
      'name': 'Beras Ramos Wangi 5kg',
      'barcode': '8991001001',
      'image_path': sampleImagePath,
      'cost_price': 65000,
      'selling_price': 74000,
      'stock': 20,
      'track_stock': 1,
      'created_at': now,
      'updated_at': now,
    };

    await db.insert('products', sample);
  }

  /// Hapus semua data produk contoh (atau reset produk)
  Future<void> clearAllProducts() async {
    final db = await database;
    await db.delete('products');
  }

  // ==================== PRODUK CRUD ====================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProducts({String? query}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.trim().isNotEmpty) {
      final sanitized = '%${query.trim()}%';
      maps = await db.rawQuery('''
        SELECT * FROM products 
        WHERE name LIKE ? OR barcode LIKE ?
        ORDER BY name ASC
      ''', [sanitized, sanitized]);
    } else {
      maps = await db.query('products', orderBy: 'name ASC');
    }

    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // ==================== TRANSAKSI PENJUALAN (ACID TRANSACTION) ====================

  /// Melakukan transaksi penjualan secara ATOMIK.
  /// Memeriksa ketersediaan stok, memotong stok, menyimpan sale dan sale_items.
  /// Jika stok tidak cukup atau terjadi error, seluruh perubahan akan di-ROLLBACK otomatis.
  Future<int> executeCheckoutTransaction({
    required Sale sale,
    required List<CartItem> cartItems,
  }) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      // 1. Verifikasi stok setiap item yang dilacak
      for (final item in cartItems) {
        if (item.product.trackStock && item.product.id != null) {
          final res = await txn.rawQuery(
            'SELECT stock, track_stock, name FROM products WHERE id = ?',
            [item.product.id],
          );
          if (res.isNotEmpty) {
            final currentStock = res.first['stock'] as int;
            final track = (res.first['track_stock'] as int) == 1;
            if (track && currentStock < item.quantity) {
              throw Exception(
                "Stok untuk '${item.product.name}' tidak mencukupi! Tersisa: $currentStock, Diminta: ${item.quantity}",
              );
            }
          }
        }
      }

      // 2. Potong stok produk
      for (final item in cartItems) {
        if (item.product.trackStock && item.product.id != null) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
            [item.quantity, DateTime.now().toIso8601String(), item.product.id],
          );
        }
      }

      // 3. Simpan data header penjualan
      final saleId = await txn.insert('sales', sale.toMap());

      // 4. Simpan rincian item penjualan
      for (final item in cartItems) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id ?? 0,
          'product_name': item.product.name,
          'cost_price': item.product.costPrice,
          'selling_price': item.product.sellingPrice,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        });
      }

      return saleId;
    });
  }

  // ==================== LAPORAN & HISTORI PENJUALAN ====================

  /// Mengambil daftar riwayat penjualan berdasarkan rentang tanggal
  Future<List<Sale>> getSales({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      whereClause = 'created_at >= ? AND created_at <= ?';
      whereArgs = [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
    } else if (startDate != null) {
      whereClause = 'created_at >= ?';
      whereArgs = [startDate.toIso8601String()];
    }

    final salesMaps = await db.query(
      'sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<Sale> sales = [];
    for (final sMap in salesMaps) {
      final saleId = sMap['id'] as int;
      final itemsMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final items = itemsMaps.map((i) => SaleItem.fromMap(i)).toList();
      sales.add(Sale.fromMap(sMap, items: items));
    }

    return sales;
  }

  /// Ringkasan laporan: Total Omzet, Total HPP, Estimasi Laba Untung, Jumlah Transaksi
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = '''
      SELECT 
        COUNT(id) as transaction_count,
        COALESCE(SUM(total_amount), 0) as total_omzet,
        COALESCE(SUM(total_cost), 0) as total_cost
      FROM sales
    ''';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      query += ' WHERE created_at >= ? AND created_at <= ?';
      args = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final res = await db.rawQuery(query, args);
    if (res.isNotEmpty) {
      final count = res.first['transaction_count'] as int? ?? 0;
      final omzet = res.first['total_omzet'] as int? ?? 0;
      final cost = res.first['total_cost'] as int? ?? 0;
      final netProfit = omzet - cost;
      return {
        'transaction_count': count,
        'total_omzet': omzet,
        'total_cost': cost,
        'net_profit': netProfit,
      };
    }

    return {
      'transaction_count': 0,
      'total_omzet': 0,
      'total_cost': 0,
      'net_profit': 0,
    };
  }

  // ==================== PENGATURAN TOKO ====================

  Future<StoreProfile> getStoreProfile() async {
    final db = await database;
    final maps = await db.query('store_settings');
    final Map<String, String> settingsMap = {};
    for (final row in maps) {
      settingsMap[row['key'] as String] = (row['value'] as String?) ?? '';
    }
    return StoreProfile.fromSettingsMap(settingsMap);
  }

  Future<void> saveStoreProfile(StoreProfile profile) async {
    final db = await database;
    final map = profile.toSettingsMap();
    final batch = db.batch();
    for (final entry in map.entries) {
      batch.insert(
        'store_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== BACKUP & RESTORE LOKAL ====================

  /// Mendapatkan path absolut file SQLite database
  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'kasir_umkm.db');
  }

  /// Ekspor seluruh database ke file JSON lokal (cadangan portabel)
  Future<String> exportBackupToJson() async {
    final db = await database;
    final products = await db.query('products');
    final sales = await db.query('sales');
    final saleItems = await db.query('sale_items');
    final settings = await db.query('store_settings');

    final backupData = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'products': products,
      'sales': sales,
      'sale_items': saleItems,
      'store_settings': settings,
    };

    final jsonString = jsonEncode(backupData);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'backup_kasir_umkm_${DateTime.now().millisecondsSinceEpoch}.json';
    final backupFile = File(p.join(tempDir.path, fileName));
    await backupFile.writeAsString(jsonString);

    return backupFile.path;
  }

  /// Pulihkan database dari file JSON cadangan
  Future<void> restoreFromJson(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      throw Exception('File backup tidak ditemukan!');
    }

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final db = await database;
    await db.transaction((txn) async {
      // Hapus data lama
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('store_settings');

      // Masukkan data baru dari backup
      if (data['products'] != null) {
        for (final p in data['products'] as List) {
          await txn.insert('products', Map<String, dynamic>.from(p as Map));
        }
      }
      if (data['sales'] != null) {
        for (final s in data['sales'] as List) {
          await txn.insert('sales', Map<String, dynamic>.from(s as Map));
        }
      }
      if (data['sale_items'] != null) {
        for (final si in data['sale_items'] as List) {
          await txn.insert('sale_items', Map<String, dynamic>.from(si as Map));
        }
      }
      if (data['store_settings'] != null) {
        for (final st in data['store_settings'] as List) {
          await txn.insert('store_settings', Map<String, dynamic>.from(st as Map));
        }
      }
    });
  }

  /// Tutup koneksi database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
