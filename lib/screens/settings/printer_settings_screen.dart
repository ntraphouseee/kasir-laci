import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_styles.dart';
import '../../providers/printer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_button.dart';

/// Layar Pengaturan & Pemasangan Printer Bluetooth Thermal 58mm
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final printer = context.read<PrinterProvider>();
      printer.checkConnection();
      printer.scanPairedDevices();
    });
  }

  Future<void> _handleConnect(String mac, String name) async {
    final printer = context.read<PrinterProvider>();
    final settings = context.read<SettingsProvider>();

    final success = await printer.connect(mac);
    if (success) {
      await settings.setPrinterInfo(mac, name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil terhubung ke printer "$name"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(printer.statusMessage ?? 'Gagal menghubungkan ke printer'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _testPrint() async {
    final printer = context.read<PrinterProvider>();
    final settings = context.read<SettingsProvider>();

    final success = await printer.printTestReceipt(settings.profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Tes struk berhasil dicetak!'
                : (printer.statusMessage ?? 'Gagal mencetak tes struk'),
          ),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final printer = context.watch<PrinterProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Printer Thermal 58mm', style: AppStyles.titleMedium),
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
            // Status Koneksi Printer
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: printer.isConnected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(
                  color: printer.isConnected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    printer.isConnected ? Icons.print : Icons.print_disabled_outlined,
                    color: printer.isConnected ? AppColors.primary : AppColors.textSecondary,
                    size: 36,
                  ),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.isConnected
                              ? 'Printer Terhubung'
                              : 'Printer Belum Terhubung',
                          style: AppStyles.titleMedium.copyWith(
                            color: printer.isConnected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.profile.printerName != null &&
                                  settings.profile.printerName!.isNotEmpty
                              ? settings.profile.printerName!
                              : 'Pilih perangkat printer bluetooth di bawah',
                          style: AppStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space16),

            // Tombol Tes Cetak
            CustomButton(
              text: 'Tes Cetak Struk (58mm)',
              icon: Icons.receipt_long,
              variant: ButtonVariant.primary,
              width: double.infinity,
              height: AppDimens.buttonHeightLarge,
              onPressed: printer.isConnected ? _testPrint : null,
            ),

            const SizedBox(height: AppDimens.space24),

            // Daftar Perangkat Bluetooth Tersedia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perangkat Bluetooth Terpasang',
                  style: AppStyles.titleMedium,
                ),
                TextButton.icon(
                  onPressed: printer.isScanning ? null : () => printer.scanPairedDevices(),
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  label: const Text('Pindai Ulang', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space8),

            if (printer.isScanning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (printer.devices.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppDimens.space20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_searching, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada printer bluetooth ditemukan.',
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pastikan printer thermal 58mm sudah Anda pasangkan (pair) terlebih dahulu di menu Pengaturan Bluetooth HP Anda.',
                      style: AppStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: printer.devices.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = printer.devices[index];
                  final isCurrentConnected =
                      printer.isConnected && printer.connectedMac == device.macAdress;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      border: Border.all(
                        color: isCurrentConnected ? AppColors.primary : AppColors.border,
                        width: isCurrentConnected ? 2 : 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        Icons.print,
                        color: isCurrentConnected ? AppColors.primary : AppColors.textSecondary,
                        size: 32,
                      ),
                      title: Text(
                        device.name.isNotEmpty ? device.name : 'Printer Thermal',
                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(device.macAdress, style: AppStyles.bodyMedium),
                      trailing: isCurrentConnected
                          ? TextButton(
                              onPressed: () => printer.disconnect(),
                              child: const Text('Putus', style: TextStyle(color: AppColors.danger)),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _handleConnect(device.macAdress, device.name),
                              child: const Text('Hubungkan'),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
