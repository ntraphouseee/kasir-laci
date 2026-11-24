import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografi berukuran besar dan jelas (Boomer-friendly)
/// Tidak ada font tipis atau kontras rendah
class AppStyles {
  // Total Bayar / Checkout Super Besar
  static const TextStyle totalCheckout = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  // Header Judul Halaman
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Subtitle / Judul Card
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Nama Produk
  static const TextStyle productName = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // Harga Produk
  static const TextStyle productPrice = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  // Body Text Standar
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body Text Sekunder (Label / Keterangan)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  // Label Tombol
  static const TextStyle buttonText = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // Badge Text
  static const TextStyle badgeText = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
  );
}
