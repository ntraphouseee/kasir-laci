import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../core/utils/receipt_helper.dart';
import '../models/sale.dart';
import '../models/store_profile.dart';

/// Provider Pengelola Koneksi & Pencetakan Printer Thermal 58mm Bluetooth
class PrinterProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isScanning = false;
  List<BluetoothInfo> _devices = [];
  String? _connectedMac;
  String? _statusMessage;

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<BluetoothInfo> get devices => _devices;
  String? get connectedMac => _connectedMac;
  String? get statusMessage => _statusMessage;

  /// Memeriksa status koneksi printer Bluetooth
  Future<void> checkConnection() async {
    try {
      final bool connectionStatus =
          await PrintBluetoothThermal.connectionStatus;
      _isConnected = connectionStatus;
      notifyListeners();
    } catch (_) {
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Memindai perangkat Bluetooth yang sudah dipasangkan (paired)
  Future<void> scanPairedDevices() async {
    _isScanning = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final bool bluetoothEnabled =
          await PrintBluetoothThermal.bluetoothEnabled;
      if (!bluetoothEnabled) {
        _statusMessage = 'Bluetooth belum aktif. Silakan aktifkan Bluetooth perangkat Anda.';
        _isScanning = false;
        notifyListeners();
        return;
      }

      final List<BluetoothInfo> result =
          await PrintBluetoothThermal.pairedBluetooths;
      _devices = result;
      if (_devices.isEmpty) {
        _statusMessage =
            'Tidak ada printer ditemukan. Pastikan printer sudah dipasangkan (paired) di pengaturan Bluetooth HP.';
      }
    } catch (e) {
      _statusMessage = 'Gagal memindai perangkat Bluetooth: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Menghubungkan ke printer thermal berdasarkan MAC Address
  Future<bool> connect(String macAddress) async {
    _statusMessage = 'Menghubungkan ke printer...';
    notifyListeners();

    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      _isConnected = result;
      if (result) {
        _connectedMac = macAddress;
        _statusMessage = 'Berhasil terhubung ke printer thermal!';
      } else {
        _statusMessage = 'Gagal terhubung. Pastikan printer menyala dan dalam jangkauan.';
      }
      notifyListeners();
      return result;
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Error koneksi printer: $e';
      notifyListeners();
      return false;
    }
  }

  /// Memutuskan koneksi printer
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _isConnected = false;
      _connectedMac = null;
      _statusMessage = 'Printer terputus';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Gagal memutus koneksi: $e';
      notifyListeners();
    }
  }

  /// Tes cetak struk percobaan ke printer 58mm
  Future<bool> printTestReceipt(StoreProfile store) async {
    try {
      final isConn = await PrintBluetoothThermal.connectionStatus;
      if (!isConn) {
        _statusMessage = 'Printer belum terhubung! Silakan hubungkan terlebih dahulu.';
        notifyListeners();
        return false;
      }

      // Buat dummy sale untuk tes
      final dummySale = Sale(
        invoiceNumber: 'TES-STRUK-001',
        totalAmount: 50000,
        totalCost: 35000,
        paymentMethod: 'TUNAI',
        paidAmount: 50000,
        changeAmount: 0,
        createdAt: DateTime.now(),
        items: [],
      );

      final bytes = await ReceiptHelper.generate58mmBytes(
        sale: dummySale,
        store: store,
      );

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      _statusMessage = result ? 'Tes cetak berhasil dikirim!' : 'Gagal mengirim data ke printer';
      notifyListeners();
      return result;
    } catch (e) {
      _statusMessage = 'Gagal cetak struk: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mencetak struk transaksi asli
  Future<bool> printSaleReceipt({
    required Sale sale,
    required StoreProfile store,
  }) async {
    try {
      final isConn = await PrintBluetoothThermal.connectionStatus;
      if (!isConn) {
        _statusMessage = 'Printer belum terhubung!';
        notifyListeners();
        return false;
      }

      final bytes = await ReceiptHelper.generate58mmBytes(
        sale: sale,
        store: store,
      );

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      _statusMessage = result ? 'Struk berhasil dicetak!' : 'Gagal mencetak struk';
      notifyListeners();
      return result;
    } catch (e) {
      _statusMessage = 'Gagal cetak struk: $e';
      notifyListeners();
      return false;
    }
  }
}
