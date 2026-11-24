import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/printer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'printer_settings_screen.dart';

/// Tab 4: Layar Pengaturan Toko, Hardware Printer & Backup Database
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SettingsProvider>().profile;
    _nameController = TextEditingController(text: profile.name);
    _addressController = TextEditingController(text: profile.address);
    _phoneController = TextEditingController(text: profile.phone);
    _footerController = TextEditingController(text: profile.receiptFooter);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final settings = context.read<SettingsProvider>();
    final updated = settings.profile.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      receiptFooter: _footerController.text.trim(),
    );

    final success = await settings.updateProfile(updated);
    if (!mounted) return;
    setState(() => _isSavingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profil toko berhasil disimpan!' : 'Gagal menyimpan profil',
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _pickQrisImage() async {
    final settings = context.read<SettingsProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await settings.setQrisImagePath(picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto QRIS toko berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _backupData() async {
    try {
      final settings = context.read<SettingsProvider>();
      final path = await settings.backupDatabase();

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Cadangan Database Kasir UMKM',
        text: 'File cadangan data produk dan transaksi Kasir UMKM.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat cadangan data: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Data?'),
        content: const Text(
          'Memulihkan data akan menimpa seluruh produk dan riwayat penjualan saat ini dengan data dari file cadangan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final productProvider = context.read<ProductProvider>();
    final salesProvider = context.read<SalesProvider>();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await settings.restoreDatabase(filePath);

        // Perbarui controller dan reload data
        final updatedProfile = settings.profile;
        _nameController.text = updatedProfile.name;
        _addressController.text = updatedProfile.address;
        _phoneController.text = updatedProfile.phone;
        _footerController.text = updatedProfile.receiptFooter;

        await productProvider.loadProducts();
        await salesProvider.loadSales();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil dipulihkan dari cadangan!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulihkan data: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final printer = context.watch<PrinterProvider>();
    final profile = settings.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Pengaturan', style: AppStyles.titleLarge),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Divider(height: 1.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAGIAN 1: PROFIL TOKO & STRUK
            Text('Profil Toko & Informasi Struk', style: AppStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Informasi ini dicetak pada bagian atas struk thermal dan nota WhatsApp.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space16),

            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Nama Toko *',
                    hint: 'Contoh: Toko Berkah UMKM',
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  CustomTextField(
                    label: 'Alamat Toko',
                    hint: 'Contoh: Jl. Pasar Baru No. 12, Jakarta',
                    controller: _addressController,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  CustomTextField(
                    label: 'No. HP / WhatsApp',
                    hint: 'Contoh: 0812-3456-7890',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  CustomTextField(
                    label: 'Catatan Kaki Struk (Footer)',
                    hint: 'Terima kasih telah berbelanja!',
                    controller: _footerController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppDimens.space16),
                  CustomButton(
                    text: 'Simpan Profil Toko',
                    icon: Icons.save,
                    isLoading: _isSavingProfile,
                    width: double.infinity,
                    height: AppDimens.buttonHeightLarge,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space24),

            // BAGIAN 2: FOTO QRIS STATIS TOKO
            Text('Foto QRIS Toko', style: AppStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'QRIS ini akan ditampilkan di layar kasir saat pelanggan memilih bayar QRIS.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space12),

            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  if (profile.qrisImagePath != null &&
                      profile.qrisImagePath!.isNotEmpty &&
                      File(profile.qrisImagePath!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                      child: Image.file(
                        File(profile.qrisImagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Ganti Foto QRIS',
                            icon: Icons.image,
                            variant: ButtonVariant.outline,
                            height: 48,
                            onPressed: _pickQrisImage,
                          ),
                        ),
                        const SizedBox(width: AppDimens.space12),
                        Expanded(
                          child: CustomButton(
                            text: 'Hapus QRIS',
                            icon: Icons.delete_outline,
                            variant: ButtonVariant.danger,
                            height: 48,
                            onPressed: () => settings.setQrisImagePath(null),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(Icons.qr_code_2, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text('Belum ada foto QRIS yang diunggah', style: AppStyles.bodyMedium),
                    const SizedBox(height: AppDimens.space16),
                    CustomButton(
                      text: 'Pilih Foto QRIS dari Galeri',
                      icon: Icons.add_photo_alternate_outlined,
                      variant: ButtonVariant.secondary,
                      width: double.infinity,
                      height: AppDimens.buttonHeightLarge,
                      onPressed: _pickQrisImage,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space24),

            // BAGIAN 3: PRINTER THERMAL 58MM
            Text('Printer Thermal Bluetooth', style: AppStyles.titleMedium),
            const SizedBox(height: AppDimens.space12),

            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        printer.isConnected ? Icons.print : Icons.print_disabled,
                        color: printer.isConnected ? AppColors.primary : AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.isConnected ? 'Printer Terhubung' : 'Belum Terhubung',
                              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              profile.printerName ?? 'Belum ada printer dipilih',
                              style: AppStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space16),
                  CustomButton(
                    text: 'Atur & Tes Printer Bluetooth',
                    icon: Icons.bluetooth,
                    variant: ButtonVariant.outline,
                    width: double.infinity,
                    height: AppDimens.buttonHeightLarge,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrinterSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space24),

            // BAGIAN 4: CADANGKAN & PULIHKAN DATA (BACKUP & RESTORE)
            Text('Cadangkan & Pulihkan Data', style: AppStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Simpan database secara mandiri ke memori HP, Google Drive, atau WhatsApp tanpa perlu sewa server.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimens.space12),

            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Cadangkan Data (Backup)',
                    icon: Icons.cloud_upload_outlined,
                    variant: ButtonVariant.primary,
                    width: double.infinity,
                    height: AppDimens.buttonHeightLarge,
                    onPressed: _backupData,
                  ),
                  const SizedBox(height: AppDimens.space12),
                  CustomButton(
                    text: 'Pulihkan Data (Restore)',
                    icon: Icons.restore,
                    variant: ButtonVariant.outline,
                    width: double.infinity,
                    height: AppDimens.buttonHeightLarge,
                    onPressed: _restoreData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }
}
