import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_styles.dart';

enum ButtonVariant { primary, secondary, outline, danger }

/// Tombol Aksesibilitas Tinggi (Boomer-friendly)
/// Memiliki tinggi minimal 52-56dp, ikon + teks jelas, kontras tajam.
class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.height = AppDimens.buttonHeightLarge,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ButtonVariant.secondary:
        bgColor = AppColors.primaryLight;
        fgColor = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case ButtonVariant.outline:
        bgColor = AppColors.surface;
        fgColor = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.borderStrong, width: 1.5);
        break;
      case ButtonVariant.danger:
        bgColor = AppColors.danger;
        fgColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22, color: fgColor),
                    const SizedBox(width: AppDimens.space8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: AppStyles.buttonText.copyWith(color: fgColor),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
