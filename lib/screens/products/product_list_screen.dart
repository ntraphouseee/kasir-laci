import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/product_image_view.dart';
import 'add_edit_product_screen.dart';

/// Tab 2: Layar Manajemen Produk & Inventori
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.name}" dari daftar barang?',
          style: AppStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ProductProvider>();
              await provider.deleteProduct(product.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Barang "${product.name}" berhasil dihapus'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSampleDataMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kelola Data Contoh', style: AppStyles.titleMedium),
            const SizedBox(height: AppDimens.space16),
            ListTile(
              leading: const Icon(Icons.add_box_outlined, color: AppColors.primary, size: 28),
              title: const Text('Muat Produk Contoh Warung', style: AppStyles.bodyLarge),
              subtitle: const Text('Beras Ramos Wangi 5kg dengan foto', style: AppStyles.bodyMedium),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ProductProvider>().seedSampleData();
              },
            ),
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 28),
              title: const Text('Kosongkan Semua Barang', style: AppStyles.bodyLarge),
              subtitle: const Text('Hapus semua produk saat ingin mulai toko nyata', style: AppStyles.bodyMedium),
              onTap: () {
                Navigator.pop(ctx);
                _confirmClearAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Semua Barang?'),
        content: const Text(
          'Seluruh barang di daftar akan dihapus. Riwayat penjualan yang telah selesai tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().clearAllProducts();
            },
            child: const Text('Kosongkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Daftar Barang', style: AppStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary, size: 26),
            tooltip: 'Pilihan Data Contoh',
            onPressed: _showSampleDataMenu,
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Bar Pencarian & Tombol Tambah Barang Baru
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => productProvider.setSearchQuery(val),
                        style: AppStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau barcode...',
                          hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    productProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.space16,
                            vertical: AppDimens.space12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: AppDimens.borderWidth,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: AppDimens.borderWidth + 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),
                CustomButton(
                  text: 'Tambah Barang Baru',
                  icon: Icons.add_circle_outline,
                  width: double.infinity,
                  height: AppDimens.buttonHeightLarge,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditProductScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Daftar Barang
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : products.isEmpty
                    ? EmptyStateView(
                        title: 'Belum Ada Barang',
                        subtitle:
                            'Tekan "Tambah Barang Baru" di atas atau muat data contoh warung.',
                        icon: Icons.inventory_2_outlined,
                        buttonText: 'Muat Produk Contoh Warung',
                        buttonIcon: Icons.add_box_outlined,
                        onButtonPressed: () => productProvider.seedSampleData(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimens.space12),
                        itemCount: products.length,
                        separatorBuilder: (_, index) => const SizedBox(height: AppDimens.space12),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _buildProductListItem(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: product.isOutOfStock
              ? AppColors.danger
              : (product.isLowStock ? AppColors.warning : AppColors.border),
          width: AppDimens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageView(
                imagePath: product.imagePath,
                width: 56,
                height: 56,
                borderRadius: AppDimens.radiusSmall,
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppStyles.productName.copyWith(fontSize: 18),
                    ),
                    if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.qr_code, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            product.barcode!,
                            style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              _buildStockBadge(product),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimens.space12),

          // Baris Harga Modal, Jual, dan Estimasi Untung
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Jual', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: AppStyles.productPrice.copyWith(fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Modal (HPP)', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.format(product.costPrice),
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Untung/Unit', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '+${CurrencyFormatter.format(product.profitPerUnit)}',
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: product.profitPerUnit >= 0 ? AppColors.primary : AppColors.danger,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),

          // Tombol Tindakan Jelas (Tanpa Swipe Tersembunyi)
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Ubah Data',
                  icon: Icons.edit_outlined,
                  variant: ButtonVariant.outline,
                  height: 48,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditProductScreen(product: product),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: CustomButton(
                  text: 'Hapus',
                  icon: Icons.delete_outline,
                  variant: ButtonVariant.danger,
                  height: 48,
                  onPressed: () => _confirmDelete(product),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(Product product) {
    if (!product.trackStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Jasa / Tanpa Stok',
          style: AppStyles.badgeText.copyWith(color: Colors.blue.shade800),
        ),
      );
    }

    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.danger),
        ),
        child: Text(
          'Stok Habis (0)',
          style: AppStyles.badgeText.copyWith(color: AppColors.danger),
        ),
      );
    }

    if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning),
        ),
        child: Text(
          'Stok Menipis (${product.stock})',
          style: AppStyles.badgeText.copyWith(color: AppColors.warning),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Stok: ${product.stock}',
        style: AppStyles.badgeText.copyWith(color: AppColors.primary),
      ),
    );
  }
}
