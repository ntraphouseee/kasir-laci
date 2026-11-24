import 'package:flutter/foundation.dart';
import '../core/database/app_database.dart';
import '../models/store_profile.dart';

/// Provider Pengelola Pengaturan Toko & Backup Database
class SettingsProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  StoreProfile _profile = const StoreProfile();
  bool _isLoading = false;
  String? _statusMessage;

  StoreProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _db.getStoreProfile();
    } catch (e) {
      _statusMessage = 'Gagal memuat profil toko: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(StoreProfile newProfile) async {
    try {
      await _db.saveStoreProfile(newProfile);
      _profile = newProfile;
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Gagal menyimpan profil: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> setQrisImagePath(String? path) async {
    final updated = _profile.copyWith(qrisImagePath: path);
    await updateProfile(updated);
  }

  Future<void> setPrinterInfo(String mac, String name) async {
    final updated = _profile.copyWith(printerMac: mac, printerName: name);
    await updateProfile(updated);
  }

  /// Ekspor cadangan database ke file JSON lokal
  Future<String> backupDatabase() async {
    return await _db.exportBackupToJson();
  }

  /// Pulihkan database dari file cadangan JSON
  Future<void> restoreDatabase(String filePath) async {
    await _db.restoreFromJson(filePath);
    await loadProfile();
  }
}
