import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/product_image_view.dart';
import 'barcode_scanner_screen.dart';
import 'checkout_dialog.dart';

/// Tab 1: Layar Kasir / Point of Sale (POS)
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

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

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final productProvider = context.read<ProductProvider>();
      final cartProvider = context.read<CartProvider>();

      final product = await productProvider.findByBarcode(barcode);
      if (product != null) {
        final err = cartProvider.addToCart(product);
        HapticFeedback.lightImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                err ?? 'Ditambahkan: ${product.name}',
                style: AppStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: err != null ? AppColors.danger : AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Barcode "$barcode" belum terdaftar di menu Barang.',
                style: AppStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _onAddToCart(Product product) {
    HapticFeedback.lightImpact();
    final cart = context.read<CartProvider>();
    final err = cart.addToCart(product);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCheckoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final products = productProvider.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Kasir Laci', style: AppStyles.titleLarge),
        actions: [
          // Toggle tampilan Grid / List
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined,
              color: AppColors.textPrimary,
              size: 26,
            ),
            tooltip: _isGridView ? 'Ganti ke Daftar' : 'Ganti ke Kisi',
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
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
          // Bar Pencarian & Tombol Scan Barcode Besar
          Container(
            padding: const EdgeInsets.all(AppDimens.space16),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => productProvider.setSearchQuery(val),
                    style: AppStyles.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang...',
                      hintStyle: AppStyles.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
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
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                          width: AppDimens.borderWidth,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: AppDimens.borderWidth + 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                CustomButton(
                  text: 'Scan',
                  icon: Icons.qr_code_scanner,
                  variant: ButtonVariant.primary,
                  height: 52,
                  onPressed: _scanBarcode,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Daftar Produk (Grid atau List)
          Expanded(
            child: productProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : products.isEmpty
                    ? EmptyStateView(
                        title: 'Belum Ada Barang',
                        subtitle:
                            'Tambah produk di menu "Barang" atau masukkan data contoh.',
                        icon: Icons.inventory_2_outlined,
                        buttonText: 'Muat Produk Contoh Warung',
                        buttonIcon: Icons.add_box_outlined,
                        onButtonPressed: () =>
                            productProvider.seedSampleData(),
                      )
                    : _isGridView
                        ? _buildProductGrid(products, cart)
                        : _buildProductList(products, cart),
          ),

          // STICKY BOTTOM GREEN CHECKOUT BAR
          if (cart.totalQuantity > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: AppDimens.borderWidth,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    offset: const Offset(0, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Rincian Singkat Keranjang
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${cart.totalQuantity} Item',
                                  style: AppStyles.badgeText
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(cart.totalAmount),
                            style: AppStyles.totalCheckout.copyWith(fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    // Tombol Keranjang
                    CustomButton(
                      text: 'Keranjang',
                      icon: Icons.shopping_cart_outlined,
                      height: AppDimens.buttonHeightLarge,
                      onPressed: _showCheckoutSheet,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, CartProvider cart) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // UI Responsif Dinamis: Saat layar ditarik melebar atau menyempit,
        // jumlah kolom bertambah / berkurang otomatis, dan tinggi kartu
        // selalu stabil pada 250px sehingga kartu tidak akan pernah gepeng / overflow!
        final isVeryNarrow = constraints.maxWidth < 320;

        return GridView.builder(
          padding: const EdgeInsets.all(AppDimens.space12),
          gridDelegate: isVeryNarrow
              ? const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 130,
                  crossAxisSpacing: AppDimens.space12,
                  mainAxisSpacing: AppDimens.space12,
                )
              : const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 250,
                  crossAxisSpacing: AppDimens.space12,
                  mainAxisSpacing: AppDimens.space12,
                ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final qtyInCart = cart.getProductQuantity(product.id);
            return _buildProductCard(product, qtyInCart, cart);
          },
        );
      },
    );
  }

  Widget _buildProductList(List<Product> products, CartProvider cart) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.space12),
      itemCount: products.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppDimens.space12),
      itemBuilder: (context, index) {
        final product = products[index];
        final qtyInCart = cart.getProductQuantity(product.id);
        return _buildProductListTile(product, qtyInCart, cart);
      },
    );
  }

  Widget _buildProductCard(Product product, int qtyInCart, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: product.isOutOfStock
              ? AppColors.danger
              : (product.isLowStock
                  ? AppColors.warning
                  : AppColors.border),
          width: AppDimens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Status Stok & Indikator Keranjang (Flexible & Compact agar tidak overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildStockBadge(product)),
              if (qtyInCart > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '$qtyInCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Foto Produk / Placeholder Hangat (Fleksibel, adaptif ke tinggi kartu agar tidak pernah overflow)
          Expanded(
            child: Center(
              child: ProductImageView(
                imagePath: product.imagePath,
                width: double.infinity,
                height: double.infinity,
                borderRadius: AppDimens.radiusSmall,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Nama Barang
          Text(
            product.name,
            style: AppStyles.productName.copyWith(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Harga Jual
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(product.sellingPrice),
              style: AppStyles.productPrice.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(height: 6),

          // TOMBOL EKSPLISIT + / STEPPER (Touch Target 44dp Boomer-Friendly)
          if (qtyInCart == 0)
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.isOutOfStock
                      ? AppColors.borderStrong
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: product.isOutOfStock
                    ? null
                    : () => _onAddToCart(product),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 20, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      product.isOutOfStock ? 'Habis' : '+ Tambah',
                      style: AppStyles.buttonText
                          .copyWith(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cart.decrementQuantity(product.id!);
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.remove, color: AppColors.primary, size: 20),
                    ),
                  ),
                  Text(
                    '$qtyInCart',
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  InkWell(
                    onTap: () => _onAddToCart(product),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.add, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductListTile(Product product, int qtyInCart, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: product.isOutOfStock
              ? AppColors.danger
              : (product.isLowStock
                  ? AppColors.warning
                  : AppColors.border),
          width: AppDimens.borderWidth,
        ),
      ),
      child: Row(
        children: [
          // Foto Produk Thumbnail 56x56
          ProductImageView(
            imagePath: product.imagePath,
            width: 56,
            height: 56,
            borderRadius: AppDimens.radiusSmall,
          ),
          const SizedBox(width: AppDimens.space12),

          // Rincian Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppStyles.productName.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppDimens.space8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice),
                      style: AppStyles.productPrice.copyWith(fontSize: 16),
                    ),
                    _buildStockBadge(product),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space8),

          // TOMBOL EKSPLISIT + / STEPPER (FEATURE 1: Touch Target >= 48dp)
          if (qtyInCart == 0)
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: product.isOutOfStock
                      ? AppColors.borderStrong
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                ),
                onPressed: product.isOutOfStock
                    ? null
                    : () => _onAddToCart(product),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
            )
          else
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      cart.decrementQuantity(product.id!);
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: const SizedBox(
                      width: 38,
                      height: 48,
                      child: Icon(Icons.remove, color: AppColors.primary, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '$qtyInCart',
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _onAddToCart(product),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: const SizedBox(
                      width: 38,
                      height: 48,
                      child: Icon(Icons.add, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(Product product) {
    if (!product.trackStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Jasa',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.badgeText.copyWith(color: Colors.blue.shade800, fontSize: 11),
        ),
      );
    }

    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Habis',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.badgeText.copyWith(color: AppColors.danger, fontSize: 11),
        ),
      );
    }

    if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Sisa ${product.stock}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.badgeText.copyWith(color: AppColors.warning, fontSize: 11),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Stok: ${product.stock}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.badgeText.copyWith(color: AppColors.primary, fontSize: 11),
      ),
    );
  }
}
