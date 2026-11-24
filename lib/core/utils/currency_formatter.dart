import 'package:intl/intl.dart';

/// Formatter mata uang Rupiah Indonesia (Rp 15.000)
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka integer ke string Rupiah: misal 15000 -> "Rp 15.000"
  static String format(int amount) {
    return _formatter.format(amount);
  }

  /// Format angka tanpa simbol "Rp ": misal 15000 -> "15.000"
  static String formatNumber(int amount) {
    final formatCompact = NumberFormat('#,###', 'id_ID');
    return formatCompact.format(amount);
  }

  /// Parse string input (misal "15.000" atau "15000") ke int
  static int parse(String input) {
    if (input.trim().isEmpty) return 0;
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
