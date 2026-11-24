import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_umkm_offline/models/cart_item.dart';
import 'package:kasir_umkm_offline/models/product.dart';
import 'package:kasir_umkm_offline/models/sale.dart';
import 'package:kasir_umkm_offline/models/sale_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inisialisasi SQLite FFI untuk lingkungan test Flutter di desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
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
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Uji Migrasi Skema SQLite v1 ke v2 (Penambahan kolom image_path)', () async {
    // 1. Buka database versi 1 tanpa kolom image_path
    final testDbPath = 'migration_test_${DateTime.now().millisecondsSinceEpoch}.db';
    var v1Db = await databaseFactory.openDatabase(
      testDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              barcode TEXT,
              cost_price INTEGER NOT NULL DEFAULT 0,
              selling_price INTEGER NOT NULL DEFAULT 0,
              stock INTEGER NOT NULL DEFAULT 0,
              track_stock INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    // Masukkan 1 produk pada schema v1
    final now = DateTime.now().toIso8601String();
    final pId = await v1Db.insert('products', {
      'name': 'Gula Pasir 1kg',
      'barcode': '899991',
      'cost_price': 14000,
      'selling_price': 16500,
      'stock': 8,
      'track_stock': 1,
      'created_at': now,
      'updated_at': now,
    });
    expect(pId, isPositive);
    await v1Db.close();

    // 2. Buka database dengan versi 2 dan jalankan onUpgrade
    final v2Db = await databaseFactory.openDatabase(
      testDbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT;');
          }
        },
      ),
    );

    // 3. Verifikasi data lama tetap utuh
    final oldProduct = await v2Db.query('products', where: 'id = ?', whereArgs: [pId]);
    expect(oldProduct.length, equals(1));
    expect(oldProduct.first['name'], equals('Gula Pasir 1kg'));
    expect(oldProduct.first['image_path'], isNull);

    // 4. Verifikasi kolom image_path baru dapat diupdate
    await v2Db.update(
      'products',
      {'image_path': '/path/to/gula.jpg'},
      where: 'id = ?',
      whereArgs: [pId],
    );

    final updatedProduct = await v2Db.query('products', where: 'id = ?', whereArgs: [pId]);
    expect(updatedProduct.first['image_path'], equals('/path/to/gula.jpg'));

    await v2Db.close();
    await databaseFactory.deleteDatabase(testDbPath);
  });

  test('Uji Rollback Transaksi Atomik SQLite Ketika Stok Tidak Mencukupi', () async {
    // 1. Masukkan produk awal dengan stok terbatas (hanya 2 pcs)
    final now = DateTime.now().toIso8601String();
    final productId = await db.insert('products', {
      'name': 'Beras Ramos 5kg',
      'barcode': '8991001',
      'cost_price': 65000,
      'selling_price': 74000,
      'stock': 2, // Stok awal = 2
      'track_stock': 1,
      'created_at': now,
      'updated_at': now,
    });

    final product = Product(
      id: productId,
      name: 'Beras Ramos 5kg',
      costPrice: 65000,
      sellingPrice: 74000,
      stock: 2,
      trackStock: true,
    );

    // 2. Buat permintaan keranjang yang melebihi stok (minta 5 pcs)
    final requestedQuantity = 5;
    final cartItems = [
      CartItem(product: product, quantity: requestedQuantity),
    ];

    final sale = Sale(
      invoiceNumber: 'INV-TEST-001',
      totalAmount: 74000 * requestedQuantity,
      totalCost: 65000 * requestedQuantity,
      paymentMethod: 'TUNAI',
      paidAmount: 400000,
      changeAmount: 30000,
      items: [
        SaleItem(
          productId: productId,
          productName: product.name,
          costPrice: product.costPrice,
          sellingPrice: product.sellingPrice,
          quantity: requestedQuantity,
          subtotal: 74000 * requestedQuantity,
        ),
      ],
    );

    // 3. Eksekusi transaksi atomik yang harus GAGAL dan melempar Exception
    bool exceptionThrown = false;
    try {
      await db.transaction((txn) async {
        // Validasi stok
        for (final item in cartItems) {
          if (item.product.trackStock) {
            final res = await txn.rawQuery(
              'SELECT stock, track_stock, name FROM products WHERE id = ?',
              [item.product.id],
            );
            if (res.isNotEmpty) {
              final currentStock = res.first['stock'] as int;
              final track = (res.first['track_stock'] as int) == 1;
              if (track && currentStock < item.quantity) {
                throw Exception(
                  "Stok untuk '${item.product.name}' tidak mencukupi (Tersisa: $currentStock, Diminta: ${item.quantity})",
                );
              }
            }
          }
        }

        // Potong stok
        for (final item in cartItems) {
          if (item.product.trackStock) {
            await txn.rawUpdate(
              'UPDATE products SET stock = stock - ? WHERE id = ?',
              [item.quantity, item.product.id],
            );
          }
        }

        final saleId = await txn.insert('sales', sale.toMap());
        for (final item in cartItems) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': item.product.id,
            'product_name': item.product.name,
            'cost_price': item.product.costPrice,
            'selling_price': item.product.sellingPrice,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          });
        }
      });
    } catch (e) {
      exceptionThrown = true;
      expect(e.toString(), contains('tidak mencukupi'));
    }

    // 4. Verifikasi Exception terlempar
    expect(exceptionThrown, isTrue);

    // 5. VERIFIKASI ROLLBACK TOTAL:
    // a. Stok produk harus tetap 2 (tidak berkurang sama sekali)
    final productCheck = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    expect(productCheck.first['stock'], equals(2));

    // b. Tabel sales harus tetap kosong (0 rows)
    final salesCount = await db.query('sales');
    expect(salesCount.length, equals(0));

    // c. Tabel sale_items harus tetap kosong (0 rows)
    final itemsCount = await db.query('sale_items');
    expect(itemsCount.length, equals(0));
  });

  test('Uji Transaksi Atomik Berhasil Ketika Stok Mencukupi', () async {
    // 1. Masukkan produk awal dengan stok 10
    final now = DateTime.now().toIso8601String();
    final productId = await db.insert('products', {
      'name': 'Minyak Goreng 2L',
      'barcode': '8991002',
      'cost_price': 31000,
      'selling_price': 36000,
      'stock': 10,
      'track_stock': 1,
      'created_at': now,
      'updated_at': now,
    });

    final product = Product(
      id: productId,
      name: 'Minyak Goreng 2L',
      costPrice: 31000,
      sellingPrice: 36000,
      stock: 10,
      trackStock: true,
    );

    // Beli 3 pcs
    final buyQty = 3;
    final cartItems = [CartItem(product: product, quantity: buyQty)];

    final sale = Sale(
      invoiceNumber: 'INV-TEST-002',
      totalAmount: 36000 * buyQty, // 108.000
      totalCost: 31000 * buyQty, // 93.000
      paymentMethod: 'TUNAI',
      paidAmount: 110000,
      changeAmount: 2000,
    );

    // Jalankan transaksi
    await db.transaction((txn) async {
      for (final item in cartItems) {
        if (item.product.trackStock) {
          final res = await txn.rawQuery(
            'SELECT stock, track_stock, name FROM products WHERE id = ?',
            [item.product.id],
          );
          final currentStock = res.first['stock'] as int;
          if (currentStock < item.quantity) {
            throw Exception('Stok tidak cukup');
          }
        }
      }

      for (final item in cartItems) {
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );
      }

      final saleId = await txn.insert('sales', sale.toMap());
      for (final item in cartItems) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'cost_price': item.product.costPrice,
          'selling_price': item.product.sellingPrice,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        });
      }
    });

    // Verifikasi stok berkurang dari 10 menjadi 7
    final productCheck = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    expect(productCheck.first['stock'], equals(7));

    // Verifikasi data penjualan tersimpan
    final salesRows = await db.query('sales');
    expect(salesRows.length, equals(1));
    expect(salesRows.first['total_amount'], equals(108000));

    // Verifikasi detail item tersimpan
    final itemRows = await db.query('sale_items');
    expect(itemRows.length, equals(1));
    expect(itemRows.first['quantity'], equals(3));
  });
}
