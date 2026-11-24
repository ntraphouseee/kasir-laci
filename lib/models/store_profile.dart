/// Model Profil Toko, Struk, dan Pengaturan Hardware
class StoreProfile {
  final String name;
  final String address;
  final String phone;
  final String receiptFooter;
  final String? qrisImagePath;
  final String? printerMac;
  final String? printerName;

  const StoreProfile({
    this.name = 'Kasir Laci',
    this.address = 'Jl. Pasar Baru No. 12, Indonesia',
    this.phone = '0812-3456-7890',
    this.receiptFooter = 'Terima kasih telah berbelanja!\nBarang yang sudah dibeli tidak dapat ditukar.',
    this.qrisImagePath,
    this.printerMac,
    this.printerName,
  });

  StoreProfile copyWith({
    String? name,
    String? address,
    String? phone,
    String? receiptFooter,
    String? qrisImagePath,
    String? printerMac,
    String? printerName,
  }) {
    return StoreProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      qrisImagePath: qrisImagePath ?? this.qrisImagePath,
      printerMac: printerMac ?? this.printerMac,
      printerName: printerName ?? this.printerName,
    );
  }

  Map<String, String> toSettingsMap() {
    final map = <String, String>{
      'store_name': name,
      'store_address': address,
      'store_phone': phone,
      'receipt_footer': receiptFooter,
    };
    if (qrisImagePath != null) map['qris_image_path'] = qrisImagePath!;
    if (printerMac != null) map['printer_mac'] = printerMac!;
    if (printerName != null) map['printer_name'] = printerName!;
    return map;
  }

  factory StoreProfile.fromSettingsMap(Map<String, String> map) {
    return StoreProfile(
      name: map['store_name'] ?? 'Kasir Laci',
      address: map['store_address'] ?? 'Jl. Pasar Baru No. 12, Indonesia',
      phone: map['store_phone'] ?? '0812-3456-7890',
      receiptFooter: map['receipt_footer'] ??
          'Terima kasih telah berbelanja!\nBarang yang sudah dibeli tidak dapat ditukar.',
      qrisImagePath: map['qris_image_path'],
      printerMac: map['printer_mac'],
      printerName: map['printer_name'],
    );
  }
}
