import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'receipt_screen.dart';

/// Bottom Sheet / Layar Pembayaran & Checkout Kasir
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  String _paymentMethod = 'TUNAI'; // 'TUNAI' atau 'QRIS'
  int _cashGiven = 0;
  final TextEditingController _cashController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    // Default uang pas saat pertama buka
    _cashGiven = cart.totalAmount;
    _cashController.text = CurrencyFormatter.formatNumber(_cashGiven);
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _setCashGiven(int amount) {
    setState(() {
      _cashGiven = amount;
      _cashController.text = CurrencyFormatter.formatNumber(amount);
    });
  }

  Future<void> _handleConfirmPayment(int totalAmount) async {
    if (_paymentMethod == 'TUNAI' && _cashGiven < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uang pembayaran tunai masih kurang!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final salesProvider = context.read<SalesProvider>();
      final productProvider = context.read<ProductProvider>();

      // Eksekusi transaksi database secara atomik
      final completedSale = await salesProvider.processCheckout(
        paidAmount: _paymentMethod == 'QRIS' ? totalAmount : _cashGiven,
        paymentMethod: _paymentMethod,
        cartItems: cartProvider.items,
      );

      // Bersihkan keranjang dan perbarui stok produk
      cartProvider.clear();
      await productProvider.loadProducts();

      if (mounted) {
        Navigator.pop(context); // Tutup bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(sale: completedSale),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: AppStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>().profile;
    final totalAmount = cart.totalAmount;
    final changeAmount = _cashGiven - totalAmount;
    final isCashSufficient = _cashGiven >= totalAmount;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusLarge),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Drag Handle & Title
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rincian & Pembayaran',
                      style: AppStyles.titleLarge.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Konten Fleksibel
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppDimens.space16),
                  children: [
                    // Rincian Item di Keranjang (Dapat diubah kuantitasnya)
                    Text(
                      'Barang yang Dibeli (${cart.totalQuantity} pcs)',
                      style: AppStyles.titleMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    ...cart.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDimens.space8),
                        padding: const EdgeInsets.all(AppDimens.space12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                        item.product.sellingPrice),
                                    style: AppStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            // Stepper kuantitas besar (Boomer-friendly)
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => cart.decrementQuantity(
                                      item.product.id!),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(Icons.remove, size: 22),
                                  ),
                                ),
                                Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 44),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final err = cart.incrementQuantity(
                                        item.product.id!);
                                    if (err != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: AppColors.danger,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(Icons.add, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppDimens.space16),

                    // Pilihan Metode Pembayaran (Tunai / QRIS)
                    Text(
                      'Pilih Metode Pembayaran',
                      style: AppStyles.titleMedium.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimens.space8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _paymentMethod = 'TUNAI';
                                _cashGiven = totalAmount;
                                _cashController.text =
                                    CurrencyFormatter.formatNumber(_cashGiven);
                              });
                            },
                            child: Container(
                              height: AppDimens.minTouchTarget,
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'TUNAI'
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusMedium),
                                border: Border.all(
                                  color: _paymentMethod == 'TUNAI'
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: _paymentMethod == 'TUNAI' ? 2.0 : 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payments_outlined,
                                    color: _paymentMethod == 'TUNAI'
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppDimens.space8),
                                  Text(
                                    'Tunai',
                                    style: AppStyles.buttonText.copyWith(
                                      color: _paymentMethod == 'TUNAI'
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _paymentMethod = 'QRIS';
                              });
                            },
                            child: Container(
                              height: AppDimens.minTouchTarget,
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'QRIS'
                                    ? Colors.purple.shade50
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusMedium),
                                border: Border.all(
                                  color: _paymentMethod == 'QRIS'
                                      ? Colors.purple.shade700
                                      : AppColors.border,
                                  width: _paymentMethod == 'QRIS' ? 2.0 : 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    color: _paymentMethod == 'QRIS'
                                        ? Colors.purple.shade800
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppDimens.space8),
                                  Text(
                                    'QRIS',
                                    style: AppStyles.buttonText.copyWith(
                                      color: _paymentMethod == 'QRIS'
                                          ? Colors.purple.shade800
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimens.space16),

                    // KONTEN METODE TUNAI
                    if (_paymentMethod == 'TUNAI') ...[
                      // Tombol Cepat Pecahan Uang Rupiah
                      Text(
                        'Pilihan Cepat Uang Tunai',
                        style: AppStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickCashChip('Uang Pas', totalAmount),
                          if (totalAmount < 10000)
                            _buildQuickCashChip('Rp 10.000', 10000),
                          if (totalAmount < 20000)
                            _buildQuickCashChip('Rp 20.000', 20000),
                          if (totalAmount < 50000)
                            _buildQuickCashChip('Rp 50.000', 50000),
                          _buildQuickCashChip('Rp 100.000', 100000),
                          _buildQuickCashChip('Rp 200.000', 200000),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // Input Manual Nominal Uang Diterima
                      CustomTextField(
                        label: 'Nominal Uang yang Diterima',
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        prefixText: 'Rp ',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          setState(() {
                            _cashGiven = CurrencyFormatter.parse(val);
                          });
                        },
                      ),

                      const SizedBox(height: AppDimens.space16),

                      // KOTAK KEMBALIAN BESAR RAMAH MATA
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: isCashSufficient
                              ? AppColors.primaryLight
                              : AppColors.dangerLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMedium),
                          border: Border.all(
                            color: isCashSufficient
                                ? AppColors.primary
                                : AppColors.danger,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCashSufficient
                                      ? 'Uang Kembalian'
                                      : 'Uang Kurang',
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isCashSufficient
                                        ? AppColors.primary
                                        : AppColors.danger,
                                  ),
                                ),
                                Text(
                                  isCashSufficient
                                      ? 'Berikan ke pembeli'
                                      : 'Nominal belum mencukupi',
                                  style: AppStyles.bodyMedium,
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(changeAmount.abs()),
                              style: AppStyles.totalCheckout.copyWith(
                                color: isCashSufficient
                                    ? AppColors.primary
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // KONTEN METODE QRIS
                    if (_paymentMethod == 'QRIS') ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMedium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            if (settings.qrisImagePath != null &&
                                settings.qrisImagePath!.isNotEmpty &&
                                File(settings.qrisImagePath!).existsSync()) ...[
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusSmall),
                                child: Image.file(
                                  File(settings.qrisImagePath!),
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: AppDimens.space8),
                              const Text(
                                'Arahkan pelanggan untuk memindai kode QRIS di atas.',
                                style: AppStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ] else ...[
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMedium),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppDimens.space12),
                              Text(
                                'Belum Ada Foto QRIS Toko',
                                style: AppStyles.titleMedium
                                    .copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: AppDimens.space4),
                              const Text(
                                'Anda dapat mengunggah gambar QRIS statis toko di menu "Pengaturan" agar muncul otomatis di sini.',
                                style: AppStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Bar Bawah Konfirmasi Pembayaran
              Padding(
                padding: const EdgeInsets.all(AppDimens.space16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Tagihan', style: AppStyles.bodyMedium),
                          Text(
                            CurrencyFormatter.format(totalAmount),
                            style: AppStyles.totalCheckout.copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: CustomButton(
                        text: 'Konfirmasi Bayar',
                        icon: Icons.check_circle_outline,
                        isLoading: _isProcessing,
                        onPressed: (_paymentMethod == 'TUNAI' &&
                                !isCashSufficient)
                            ? null
                            : () => _handleConfirmPayment(totalAmount),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildQuickCashChip(String label, int amount) {
    final isSelected = _cashGiven == amount;
    return InkWell(
      onTap: () => _setCashGiven(amount),
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
