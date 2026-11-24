import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../models/sale.dart';
import '../../models/store_profile.dart';
import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Helper untuk menyusun struk teks WhatsApp dan byte ESC/POS untuk Printer Thermal 58mm
class ReceiptHelper {
  static const int printerWidth58mm = 32; // 32 karakter per baris untuk 58mm

  /// Format pesan teks struk belanja ramah WhatsApp
  static String formatWhatsAppReceipt({
    required Sale sale,
    required StoreProfile store,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *STRUK PEMBELIAN*');
    buffer.writeln('*${store.name.toUpperCase()}*');
    if (store.address.isNotEmpty) {
      buffer.writeln(store.address);
    }
    if (store.phone.isNotEmpty) {
      buffer.writeln('Telp/WA: ${store.phone}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('No. Faktur : ${sale.invoiceNumber}');
    buffer.writeln('Waktu      : ${DateFormatter.formatFull(sale.createdAt)}');
    buffer.writeln('Kasir      : Kasir Offline');
    buffer.writeln('--------------------------------');

    for (final item in sale.items) {
      buffer.writeln('*${item.productName}*');
      final qtyPrice =
          '  ${item.quantity} x ${CurrencyFormatter.format(item.sellingPrice)}';
      final subtotal = CurrencyFormatter.format(item.subtotal);
      buffer.writeln('$qtyPrice = $subtotal');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('*TOTAL      : ${CurrencyFormatter.format(sale.totalAmount)}*');
    buffer.writeln('Metode     : ${sale.paymentMethod}');
    if (sale.paymentMethod == 'TUNAI') {
      buffer.writeln('Bayar      : ${CurrencyFormatter.format(sale.paidAmount)}');
      buffer.writeln('Kembalian  : ${CurrencyFormatter.format(sale.changeAmount)}');
    }
    buffer.writeln('--------------------------------');
    if (store.receiptFooter.isNotEmpty) {
      buffer.writeln(store.receiptFooter);
    }
    buffer.writeln('\n_Terima kasih atas kunjungan Anda!_ 🙏');

    return buffer.toString();
  }

  /// Format baris teks dengan pemisah rata kiri dan kanan (32 kolom)
  static String _lineLeftRight(String left, String right, {int width = printerWidth58mm}) {
    final spaces = width - left.length - right.length;
    if (spaces <= 0) {
      return '$left $right';
    }
    return left + (' ' * spaces) + right;
  }

  /// Membuat susunan byte ESC/POS untuk thermal printer 58mm
  static Future<List<int>> generate58mmBytes({
    required Sale sale,
    required StoreProfile store,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header Toko
    bytes += generator.text(
      store.name,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (store.address.isNotEmpty) {
      bytes += generator.text(
        store.address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (store.phone.isNotEmpty) {
      bytes += generator.text(
        'Telp: ${store.phone}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '=');
    bytes += generator.text(
      'Faktur: ${sale.invoiceNumber}',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      'Tgl   : ${DateFormatter.formatShort(sale.createdAt)}',
    );
    bytes += generator.hr(ch: '-');

    // Daftar Item
    for (final item in sale.items) {
      bytes += generator.text(
        item.productName,
        styles: const PosStyles(bold: true),
      );
      final left = ' ${item.quantity} x ${CurrencyFormatter.formatNumber(item.sellingPrice)}';
      final right = CurrencyFormatter.format(item.subtotal);
      final line = _lineLeftRight(left, right);
      bytes += generator.text(line);
    }

    bytes += generator.hr(ch: '-');

    // Ringkasan Pembayaran
    final totalLine = _lineLeftRight('TOTAL', CurrencyFormatter.format(sale.totalAmount));
    bytes += generator.text(
      totalLine,
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    final methodLine = _lineLeftRight('Metode Bayar', sale.paymentMethod);
    bytes += generator.text(methodLine);

    if (sale.paymentMethod == 'TUNAI') {
      final payLine = _lineLeftRight('Bayar Tunai', CurrencyFormatter.format(sale.paidAmount));
      bytes += generator.text(payLine);

      final changeLine = _lineLeftRight('Kembalian', CurrencyFormatter.format(sale.changeAmount));
      bytes += generator.text(
        changeLine,
        styles: const PosStyles(bold: true),
      );
    }

    bytes += generator.hr(ch: '=');

    // Footer
    if (store.receiptFooter.isNotEmpty) {
      final footerLines = store.receiptFooter.split('\n');
      for (final fLine in footerLines) {
        bytes += generator.text(
          fLine,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
