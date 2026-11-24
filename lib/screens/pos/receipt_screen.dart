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

/// Layar Struk & Sukses Transaksi Penjualan
class ReceiptScreen extends StatelessWidget {
  final Sale sale;

  const ReceiptScreen({super.key, required this.sale});

  void _shareReceiptWhatsApp(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final receiptText = ReceiptHelper.formatWhatsAppReceipt(
      sale: sale,
      store: settingsProvider.profile,
    );

    Share.share(
      receiptText,
      subject: 'Struk Pembelian ${sale.invoiceNumber}',
    );
  }

  Future<void> _printBluetooth(BuildContext context) async {
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
            success
                ? 'Struk berhasil dikirim ke printer!'
                : (printerProvider.statusMessage ??
                    'Gagal mencetak. Pastikan printer terhubung di tab Pengaturan.'),
            style: AppStyles.bodyLarge.copyWith(color: Colors.white),
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().profile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 28),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
          title: Text(
            'Transaksi Selesai',
            style: AppStyles.titleMedium,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.5),
            child: Divider(height: 1.5, color: AppColors.border),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            children: [
              // Banner Sukses
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space20,
                  horizontal: AppDimens.space16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    Text(
                      'Transaksi Berhasil!',
                      style: AppStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      sale.invoiceNumber,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Rincian Pembayaran Fisik Kertas (Crisp White Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(
                    color: AppColors.border,
                    width: AppDimens.borderWidth,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        settings.name,
                        style: AppStyles.productName.copyWith(fontSize: 18),
                      ),
                    ),
                    if (settings.address.isNotEmpty)
                      Center(
                        child: Text(
                          settings.address,
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: AppDimens.space12),
                    const Divider(color: AppColors.border, thickness: 1.5),
                    const SizedBox(height: AppDimens.space8),

                    // Baris Item Terjual
                    ...sale.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.space4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} x ${CurrencyFormatter.format(item.sellingPrice)}',
                                    style: AppStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppDimens.space8),
                    const Divider(color: AppColors.border, thickness: 1.5),
                    const SizedBox(height: AppDimens.space8),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL BELANJA',
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(sale.totalAmount),
                          style: AppStyles.totalCheckout.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space4),

                    // Metode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Metode Pembayaran', style: AppStyles.bodyMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sale.paymentMethod == 'QRIS'
                                ? Colors.purple.shade50
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sale.paymentMethod,
                            style: AppStyles.badgeText.copyWith(
                              color: sale.paymentMethod == 'QRIS'
                                  ? Colors.purple.shade800
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (sale.paymentMethod == 'TUNAI') ...[
                      const SizedBox(height: AppDimens.space4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Uang Tunai Diterima', style: AppStyles.bodyMedium),
                          Text(
                            CurrencyFormatter.format(sale.paidAmount),
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kembalian',
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(sale.changeAmount),
                            style: AppStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppDimens.space8),
                    const Divider(color: AppColors.border, thickness: 1.5),
                    const SizedBox(height: AppDimens.space4),
                    Center(
                      child: Text(
                        DateFormatter.formatFull(sale.createdAt),
                        style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space24),

              // 3 Tombol Utama Sesuai Spesifikasi:
              // 1. "Cetak Struk (Bluetooth)"
              CustomButton(
                text: 'Cetak Struk (Bluetooth)',
                icon: Icons.print_outlined,
                variant: ButtonVariant.primary,
                height: AppDimens.buttonHeightLarge,
                width: double.infinity,
                onPressed: () => _printBluetooth(context),
              ),
              const SizedBox(height: AppDimens.space12),

              // 2. "Kirim Nota ke WhatsApp"
              CustomButton(
                text: 'Kirim Nota ke WhatsApp',
                icon: Icons.chat_outlined,
                variant: ButtonVariant.secondary,
                height: AppDimens.buttonHeightLarge,
                width: double.infinity,
                onPressed: () => _shareReceiptWhatsApp(context),
              ),
              const SizedBox(height: AppDimens.space12),

              // 3. "Transaksi Baru"
              CustomButton(
                text: 'Transaksi Baru',
                icon: Icons.add_shopping_cart,
                variant: ButtonVariant.outline,
                height: AppDimens.buttonHeightLarge,
                width: double.infinity,
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              const SizedBox(height: AppDimens.space24),
            ],
          ),
        ),
      ),
    );
  }
}
