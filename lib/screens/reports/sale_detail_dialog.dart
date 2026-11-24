import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/receipt_helper.dart';
import '../../models/sale.dart';
import '../../providers/printer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';

/// Dialog Detail Riwayat Transaksi Penjualan
class SaleDetailDialog extends StatelessWidget {
  final Sale sale;

  const SaleDetailDialog({super.key, required this.sale});

  void _shareReceiptWhatsApp(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final receiptText = ReceiptHelper.formatWhatsAppReceipt(
      sale: sale,
      store: settingsProvider.profile,
    );
    Share.share(receiptText, subject: 'Struk ${sale.invoiceNumber}');
  }

  Future<void> _printReceipt(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final printerProvider = context.read<PrinterProvider>();

    final success = await printerProvider.printSaleReceipt(
      sale: sale,
      store: settingsProvider.profile,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Struk berhasil dicetak!' : (printerProvider.statusMessage ?? 'Gagal mencetak struk'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rincian Transaksi', style: AppStyles.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),

              Text(
                sale.invoiceNumber,
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                DateFormatter.formatFull(sale.createdAt),
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),

              // Rincian Item
              Text(
                'Daftar Barang',
                style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: AppStyles.bodyLarge),
                            Text(
                              '${item.quantity} x ${CurrencyFormatter.format(item.sellingPrice)} (Modal: ${CurrencyFormatter.format(item.costPrice)})',
                              style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),

              // Ringkasan Keuangan Transaksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Omzet Penjualan', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    CurrencyFormatter.format(sale.totalAmount),
                    style: AppStyles.titleMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Modal HPP', style: AppStyles.bodyMedium),
                  Text(CurrencyFormatter.format(sale.totalCost), style: AppStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laba Bersih Transaksi',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '+${CurrencyFormatter.format(sale.netProfit)}',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Metode Pembayaran', style: AppStyles.bodyMedium),
                  Text(sale.paymentMethod, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 20),

              // Tombol Cetak & Bagikan
              CustomButton(
                text: 'Cetak Ulang Struk (Bluetooth)',
                icon: Icons.print_outlined,
                variant: ButtonVariant.primary,
                width: double.infinity,
                height: 50,
                onPressed: () => _printReceipt(context),
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Kirim Ulang ke WhatsApp',
                icon: Icons.chat_outlined,
                variant: ButtonVariant.outline,
                width: double.infinity,
                height: 50,
                onPressed: () => _shareReceiptWhatsApp(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
