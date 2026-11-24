import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';

/// Widget Penampil Foto Produk dengan Fallback Placeholder Bersih & Hangat (#EFECE6)
class ProductImageView extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;

  const ProductImageView({
    super.key,
    required this.imagePath,
    this.width = 64.0,
    this.height = 64.0,
    this.borderRadius = AppDimens.radiusSmall,
    this.placeholderIcon = Icons.inventory_2_outlined,
  });

  bool get _hasValidImage {
    if (imagePath == null || imagePath!.trim().isEmpty) return false;
    try {
      final file = File(imagePath!);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFEFECE6), // Background placeholder hangat ramah mata
        child: _hasValidImage
            ? Image.file(
                File(imagePath!),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double iconSize;
        if (constraints.maxWidth.isFinite && constraints.maxHeight.isFinite) {
          iconSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.45;
        } else if (width.isFinite) {
          iconSize = width * 0.45;
        } else {
          iconSize = 32.0;
        }
        return Center(
          child: Icon(
            placeholderIcon,
            color: AppColors.textSecondary,
            size: iconSize.clamp(18.0, 48.0),
          ),
        );
      },
    );
  }
}
