import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_umkm_offline/core/utils/currency_formatter.dart';
import 'package:kasir_umkm_offline/models/product.dart';
import 'package:kasir_umkm_offline/models/sale.dart';
import 'package:kasir_umkm_offline/models/sale_item.dart';
import 'package:kasir_umkm_offline/providers/cart_provider.dart';

void main() {
  group('Pengujian Akurasi Kalkulasi Kasir & Laba Untung', () {
    test('Kalkulasi Keranjang Belanja: Total Omzet, Modal HPP, dan Keuntungan', () {
      final cart = CartProvider();

      final p1 = Product(
        id: 1,
        name: 'Beras Ramos 5kg',
        costPrice: 65000,
        sellingPrice: 74000,
        stock: 10,
      );

      final p2 = Product(
        id: 2,
        name: 'Minyak Goreng 2L',
        costPrice: 31000,
        sellingPrice: 36000,
        stock: 10,
      );

      // Tambahkan 2 Beras Ramos (Subtotal Jual: 148.000, Modal: 130.000)
      cart.addToCart(p1);
      cart.addToCart(p1);

      // Tambahkan 1 Minyak Goreng (Subtotal Jual: 36.000, Modal: 31.000)
      cart.addToCart(p2);

      expect(cart.totalQuantity, equals(3));
      expect(cart.totalAmount, equals(148000 + 36000)); // 184.000
      expect(cart.totalCost, equals(130000 + 31000)); // 161.000

      // Estimasi Laba = 184.000 - 161.000 = 23.000
      final expectedProfit = cart.totalAmount - cart.totalCost;
      expect(expectedProfit, equals(23000));
    });

    test('Kalkulasi Uang Kembalian Pembayaran Tunai', () {
      const int totalAmount = 74000;

      // Kasus 1: Bayar Uang Pas
      int cashGiven = 74000;
      int change = cashGiven - totalAmount;
      expect(change, equals(0));

      // Kasus 2: Bayar Rp 100.000
      cashGiven = 100000;
      change = cashGiven - totalAmount;
      expect(change, equals(26000));

      // Kasus 3: Bayar Rp 80.000
      cashGiven = 80000;
      change = cashGiven - totalAmount;
      expect(change, equals(6000));
    });

    test('Kalkulasi Laba Bersih Transaksi Penjualan (Net Profit = Omzet - Total HPP)', () {
      final sale = Sale(
        invoiceNumber: 'INV-TEST-003',
        totalAmount: 184000,
        totalCost: 161000,
        paymentMethod: 'TUNAI',
        paidAmount: 200000,
        changeAmount: 16000,
        items: [
          SaleItem(
            productId: 1,
            productName: 'Beras Ramos 5kg',
            costPrice: 65000,
            sellingPrice: 74000,
            quantity: 2,
            subtotal: 148000,
          ),
          SaleItem(
            productId: 2,
            productName: 'Minyak Goreng 2L',
            costPrice: 31000,
            sellingPrice: 36000,
            quantity: 1,
            subtotal: 36000,
          ),
        ],
      );

      // Verifikasi net profit
      expect(sale.netProfit, equals(23000));
      expect(sale.items.first.subtotalCost, equals(130000));
      expect(sale.items.first.subtotalProfit, equals(18000));
      expect(sale.items.last.subtotalProfit, equals(5000));
      expect(
        sale.items.fold(0, (sum, i) => sum + i.subtotalProfit),
        equals(sale.netProfit),
      );
    });

    test('Formatter Mata Uang Rupiah (CurrencyFormatter)', () {
      expect(CurrencyFormatter.format(15000), contains('15.000'));
      expect(CurrencyFormatter.formatNumber(15000), equals('15.000'));
      expect(CurrencyFormatter.parse('Rp 15.000'), equals(15000));
      expect(CurrencyFormatter.parse('25.500'), equals(25500));
      expect(CurrencyFormatter.parse(''), equals(0));
    });

    test('Serialisasi Model Product dengan Kolom image_path', () {
      final product = Product(
        id: 10,
        name: 'Kopi Susu Dingin',
        barcode: '123456789',
        imagePath: '/data/user/0/app/product_images/prod_1.jpg',
        costPrice: 5000,
        sellingPrice: 10000,
        stock: 15,
        trackStock: true,
      );

      final map = product.toMap();
      expect(map['image_path'], equals('/data/user/0/app/product_images/prod_1.jpg'));

      final fromMap = Product.fromMap(map);
      expect(fromMap.imagePath, equals('/data/user/0/app/product_images/prod_1.jpg'));
      expect(fromMap.name, equals('Kopi Susu Dingin'));

      // Uji copyWith untuk hapus foto (resetImagePath: true)
      final withoutPhoto = fromMap.copyWith(resetImagePath: true);
      expect(withoutPhoto.imagePath, isNull);
    });

    test('CartProvider getProductQuantity mengembalikan jumlah tepat di keranjang', () {
      final cart = CartProvider();
      final p = Product(
        id: 99,
        name: 'Teh Celup Kotak',
        costPrice: 4000,
        sellingPrice: 6000,
        stock: 5,
      );

      expect(cart.getProductQuantity(99), equals(0));
      cart.addToCart(p);
      expect(cart.getProductQuantity(99), equals(1));
      cart.addToCart(p);
      expect(cart.getProductQuantity(99), equals(2));
      cart.decrementQuantity(99);
      expect(cart.getProductQuantity(99), equals(1));
      cart.decrementQuantity(99);
      expect(cart.getProductQuantity(99), equals(0));
    });
  });
}
