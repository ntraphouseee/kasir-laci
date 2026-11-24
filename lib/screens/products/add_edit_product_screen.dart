import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../pos/barcode_scanner_screen.dart';

/// Layar Tambah / Edit Produk & Stok
class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  String? _imagePath;
  bool _trackStock = true;
  bool _isSaving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.costPrice) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? CurrencyFormatter.formatNumber(p.sellingPrice) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '10',
    );
    _imagePath = p?.imagePath;
    _trackStock = p?.trackStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = code;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppDimens.space20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Sumber Foto Produk', style: AppStyles.titleMedium),
              const SizedBox(height: AppDimens.space16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 24),
                ),
                title: const Text('Ambil Foto (Kamera)', style: AppStyles.bodyLarge),
                subtitle: const Text('Potret barang langsung dengan kamera HP', style: AppStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProductImage(ImageSource.camera);
                },
              ),
              const Divider(color: AppColors.border),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary, size: 24),
                ),
                title: const Text('Pilih dari Galeri', style: AppStyles.bodyLarge),
                subtitle: const Text('Pilih foto barang yang sudah ada di galeri', style: AppStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProductImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProductImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Simpan permanen ke direktori aplikasi lokal agar tidak hilang saat cache dibersihkan
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'product_images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(pickedFile.path).copy(p.join(imagesDir.path, fileName));

        if (mounted) {
          setState(() {
            _imagePath = savedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama barang tidak boleh kosong!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final costPrice = CurrencyFormatter.parse(_costPriceController.text);
    final sellingPrice = CurrencyFormatter.parse(_sellingPriceController.text);
    final stock = _trackStock ? (int.tryParse(_stockController.text.trim()) ?? 0) : 0;
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

    if (sellingPrice < costPrice) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Perhatian Harga Jual'),
          content: const Text(
            'Harga jual lebih rendah daripada harga modal (HPP). Apakah Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Periksa Kembali'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tetap Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    final productProvider = context.read<ProductProvider>();
    bool success;

    if (isEdit) {
      final updated = widget.product!.copyWith(
        name: name,
        barcode: barcode,
        imagePath: _imagePath,
        resetImagePath: _imagePath == null,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        stock: stock,
        trackStock: _trackStock,
        updatedAt: DateTime.now(),
      );
      success = await productProvider.updateProduct(updated);
    } else {
      final newProduct = Product(
        name: name,
        barcode: barcode,
        imagePath: _imagePath,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        stock: stock,
        trackStock: _trackStock,
      );
      success = await productProvider.addProduct(newProduct);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Produk berhasil diperbarui!' : 'Produk berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.errorMessage ?? 'Gagal menyimpan produk'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Ubah Data Barang' : 'Tambah Barang Baru',
          style: AppStyles.titleMedium,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO PRODUK (OPSIONAL)
              Text(
                'Foto Produk (Opsional)',
                style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppDimens.space8),
              if (hasImage) ...[
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFECE6),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                    child: Image.file(
                      File(_imagePath!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Ganti Foto',
                        icon: Icons.photo_camera_outlined,
                        variant: ButtonVariant.outline,
                        height: 48,
                        onPressed: _showImageSourcePicker,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: CustomButton(
                        text: 'Hapus Foto',
                        icon: Icons.delete_outline,
                        variant: ButtonVariant.danger,
                        height: 48,
                        onPressed: () => setState(() => _imagePath = null),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                InkWell(
                  onTap: _showImageSourcePicker,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(
                        color: AppColors.borderStrong,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFECE6),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ketuk untuk Pasang Foto Barang',
                          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bisa ambil lewat Kamera langsung atau Galeri HP',
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppDimens.space20),

              // 1. Nama Barang
              CustomTextField(
                label: 'Nama Barang *',
                hint: 'Contoh: Beras Ramos Wangi 5kg',
                controller: _nameController,
              ),
              const SizedBox(height: AppDimens.space16),

              // 2. Kode / Barcode Produk + Tombol Scan Kamera
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Kode / Barcode (Opsional)',
                      hint: 'Scan atau ketik kode',
                      controller: _barcodeController,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  CustomButton(
                    text: 'Scan',
                    icon: Icons.qr_code_scanner,
                    variant: ButtonVariant.primary,
                    height: AppDimens.buttonHeightLarge,
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

              // 3. Harga Modal (HPP) & Harga Jual
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Harga Modal (HPP)',
                      hint: '0',
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      prefixText: 'Rp ',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Harga Jual *',
                      hint: '0',
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      prefixText: 'Rp ',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

              // 4. Switch Lacak Stok (Jasa / Makanan Racik tidak perlu stok)
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lacak Stok Barang',
                            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Matikan untuk produk jasa, makanan racikan, atau minuman',
                            style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _trackStock,
                      activeTrackColor: AppColors.primaryLight,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _trackStock = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // 5. Input Stok (jika lacak stok aktif)
              if (_trackStock) ...[
                CustomTextField(
                  label: 'Stok Saat Ini *',
                  hint: 'Contoh: 20',
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('pcs', style: AppStyles.bodyMedium),
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                Text(
                  'Catatan: Sistem akan memberi tanda peringatan jika stok tersisa 5 pcs atau kurang.',
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space24),
              ] else
                const SizedBox(height: AppDimens.space16),

              // Tombol Simpan
              CustomButton(
                text: isEdit ? 'Simpan Perubahan' : 'Tambah Barang ke Daftar',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                width: double.infinity,
                height: AppDimens.buttonHeightLarge,
                onPressed: _saveProduct,
              ),
              const SizedBox(height: AppDimens.space32),
            ],
          ),
        ),
      ),
    );
  }
}
