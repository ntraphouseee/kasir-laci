import 'package:intl/intl.dart';

/// Formatter tanggal dalam Bahasa Indonesia
class DateFormatter {
  static final DateFormat _fullDateTimeFormat = DateFormat(
    'EEEE, d MMMM yyyy HH:mm',
    'id_ID',
  );

  static final DateFormat _shortDateFormat = DateFormat(
    'd MMM yyyy, HH:mm',
    'id_ID',
  );

  static final DateFormat _dayDateFormat = DateFormat(
    'd MMMM yyyy',
    'id_ID',
  );

  static final DateFormat _timeFormat = DateFormat(
    'HH:mm',
    'id_ID',
  );

  /// Format lengkap: misal "Selasa, 24 November 2026 17:30"
  static String formatFull(DateTime dateTime) {
    try {
      return _fullDateTimeFormat.format(dateTime);
    } catch (_) {
      // Fallback jika locale id belum diinisialisasi
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format ringkas: misal "24 Nov 2026, 17:30"
  static String formatShort(DateTime dateTime) {
    try {
      return _shortDateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format hari & tanggal saja: misal "24 November 2026"
  static String formatDay(DateTime dateTime) {
    try {
      return _dayDateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format jam: misal "17:30"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
}
