import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/sale.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/summary_card.dart';
import 'sale_detail_dialog.dart';

/// Tab 3: Layar Laporan Penjualan & Laba Untung
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadSales();
    });
  }

  void _showSaleDetail(Sale sale) {
    showDialog(
      context: context,
      builder: (_) => SaleDetailDialog(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final sales = salesProvider.sales;
    final currentFilter = salesProvider.currentFilter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Laporan Penjualan', style: AppStyles.titleLarge),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => salesProvider.loadSales(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Filter Waktu: "Hari Ini", "Minggu Ini", "Bulan Ini"
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    _buildFilterOption(
                      label: 'Hari Ini',
                      isSelected: currentFilter == ReportFilter.hariIni,
                      onTap: () => salesProvider.loadSales(ReportFilter.hariIni),
                    ),
                    _buildFilterOption(
                      label: 'Minggu Ini',
                      isSelected: currentFilter == ReportFilter.mingguIni,
                      onTap: () => salesProvider.loadSales(ReportFilter.mingguIni),
                    ),
                    _buildFilterOption(
                      label: 'Bulan Ini',
                      isSelected: currentFilter == ReportFilter.bulanIni,
                      onTap: () => salesProvider.loadSales(ReportFilter.bulanIni),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // 3 KARTU RINGKASAN SESUAI SPESIFIKASI:
              // 1. Total Omzet
              SummaryCard(
                title: 'Total Omzet Penjualan',
                value: CurrencyFormatter.format(salesProvider.totalOmzet),
                icon: Icons.payments_outlined,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: AppDimens.space12),

              // 2. Estimasi Laba Untung (Omzet - Total HPP)
              SummaryCard(
                title: 'Estimasi Laba Untung Bersih',
                value: '+${CurrencyFormatter.format(salesProvider.netProfit)}',
                icon: Icons.trending_up,
                valueColor: salesProvider.netProfit >= 0
                    ? AppColors.primary
                    : AppColors.danger,
                iconBgColor: salesProvider.netProfit >= 0
                    ? AppColors.primaryLight
                    : AppColors.dangerLight,
              ),
              const SizedBox(height: AppDimens.space12),

              // 3. Jumlah Transaksi
              SummaryCard(
                title: 'Jumlah Transaksi',
                value: '${salesProvider.transactionCount} Transaksi',
                icon: Icons.receipt_long_outlined,
                valueColor: AppColors.textPrimary,
                iconBgColor: AppColors.background,
              ),

              const SizedBox(height: AppDimens.space24),

              // Riwayat Transaksi Penjualan
              Text(
                'Riwayat Transaksi',
                style: AppStyles.titleMedium,
              ),
              const SizedBox(height: AppDimens.space12),

              if (salesProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (sales.isEmpty)
                const EmptyStateView(
                  title: 'Belum Ada Transaksi',
                  subtitle:
                      'Transaksi penjualan pada periode ini akan muncul di sini setelah transaksi selesai.',
                  icon: Icons.receipt_outlined,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  separatorBuilder: (_, index) => const SizedBox(height: AppDimens.space12),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _buildSaleCard(sale);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyles.buttonText.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return InkWell(
      onTap: () => _showSaleDetail(sale),
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sale.invoiceNumber,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatShort(sale.createdAt),
              style: AppStyles.bodyMedium.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${sale.items.length} Macam Barang',
                  style: AppStyles.bodyMedium,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(sale.totalAmount),
                      style: AppStyles.productPrice,
                    ),
                    Text(
                      'Laba: +${CurrencyFormatter.format(sale.netProfit)}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
