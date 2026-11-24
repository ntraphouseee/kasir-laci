import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kasir_umkm_offline/main.dart';
import 'package:kasir_umkm_offline/screens/main_navigation_screen.dart';
import 'package:kasir_umkm_offline/screens/splash/splash_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'Widget Test: Memastikan SplashScreen Render dengan Gambar Poster & Loading Bar Pemanis',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const KasirUmkmApp(
          initialHome: SplashScreen(autoNavigate: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi komponen splash screen hadir
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Offline'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Widget Smoke Test: Memastikan 4 Tab Navigasi Render Tanpa Overflow Pada Layar Mobile Standar (360x800)',
    (WidgetTester tester) async {
      // Atur ukuran layar ke rasio mobile standar (360 x 800)
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Render aplikasi utama Kasir UMKM
      await tester.pumpWidget(
        const KasirUmkmApp(initialHome: MainNavigationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Verifikasi Tab Kasir Muncul
      expect(find.text('Kasir'), findsOneWidget);
      expect(find.text('Barang'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);

      // Verifikasi elemen header halaman Kasir
      expect(find.text('Kasir Laci'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);

      // 2. Berpindah ke Tab 2: Barang
      await tester.tap(find.text('Barang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Daftar Barang'), findsOneWidget);
      expect(find.text('Tambah Barang Baru'), findsOneWidget);

      // 3. Berpindah ke Tab 3: Laporan
      await tester.tap(find.text('Laporan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Laporan Penjualan'), findsOneWidget);
      expect(find.text('Total Omzet Penjualan'), findsOneWidget);
      expect(find.text('Estimasi Laba Untung Bersih'), findsOneWidget);
      expect(find.text('Jumlah Transaksi'), findsOneWidget);

      // 4. Berpindah ke Tab 4: Pengaturan
      await tester.tap(find.text('Pengaturan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pengaturan'), findsWidgets);
      expect(find.text('Profil Toko & Informasi Struk'), findsOneWidget);
      expect(find.text('Foto QRIS Toko'), findsOneWidget);
      expect(find.text('Printer Thermal Bluetooth'), findsOneWidget);
      expect(find.text('Cadangkan & Pulihkan Data'), findsOneWidget);

      // 5. Kembali ke Tab 1: Kasir
      await tester.tap(find.text('Kasir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kasir Laci'), findsOneWidget);

      // Pastikan tidak ada exception overflow / layout error
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Widget Test: Memastikan Tampilan Responsif pada Tablet / Layar Lebar (800x1280) Render Tanpa Overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const KasirUmkmApp(initialHome: MainNavigationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Kasir Laci'), findsOneWidget);
      expect(find.text('Kasir'), findsOneWidget);
      expect(find.text('Barang'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Widget Test: Tombol Tambah (+) pada Kartu Produk Menambah Item ke Keranjang dan Menampilkan Stepper',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const KasirUmkmApp(initialHome: MainNavigationScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Jika produk contoh termuat, tombol "+ Tambah" akan muncul pada setiap card produk
      final addButtons = find.text('+ Tambah');
      if (addButtons.evaluate().isNotEmpty) {
        // Tekan tombol + Tambah pertama
        await tester.tap(addButtons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Sticky bottom checkout bar harus muncul dengan minimal 1 item
        expect(find.text('Keranjang'), findsOneWidget);
        expect(find.text('1 Item'), findsOneWidget);

        // Pada card tersebut sekarang muncul stepper angka 1
        expect(find.text('1'), findsWidgets);
      }

      expect(tester.takeException(), isNull);
    },
  );
}
