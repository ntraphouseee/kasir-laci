# Kasir Laci

> **Lightweight, 100% Offline-First Point of Sale (POS) & Inventory Mobile System for Indonesian MSMEs.**  
> Engineered with Flutter, native SQLite ACID transactions, Bluetooth ESC/POS thermal printing, and zero cloud server dependencies.

[![Download APK](https://img.shields.io/badge/Download-Release%20APK%20(v1.0.0)-2ea44f?logo=android&logoColor=white)](https://github.com/ntraphouseee/kasir-laci/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/Database-SQLite%203-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Android](https://img.shields.io/badge/Platform-Android%20API%2023+-3DDC84?logo=android&logoColor=white)](https://android.com)
[![Tests](https://img.shields.io/badge/Tests-13%2F13%20Passing%20(100%25)-brightgreen)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()

---

## 📥 Direct APK Download

Siap pakai tanpa biaya langganan cloud dan tanpa perlu Google Play Store. Pilih file APK sesuai arsitektur perangkat Anda:

| Package Variant | Binary Size | Architecture / Device Compatibility | Direct Download Link |
| :--- | :--- | :--- | :--- |
| **Kasir Laci (ARM64)** *(Recommended)* | **~26.5 MB** | Modern 64-bit Android smartphones & tablets (95%+ device) | [Download ARM64 APK](https://github.com/ntraphouseee/kasir-laci/releases/download/v1.0.0/Kasir-Laci-v1.0.0-arm64.apk) |
| **Kasir Laci (ARMv7)** | **~22.5 MB** | Legacy 32-bit budget Android devices | [Download ARMv7 APK](https://github.com/ntraphouseee/kasir-laci/releases/download/v1.0.0/Kasir-Laci-v1.0.0-armeabi-v7a.apk) |
| **Kasir Laci (Universal)** | **~70.8 MB** | Multi-ABI Fat binary (semua jenis CPU / Emulator) | [Download Universal APK](https://github.com/ntraphouseee/kasir-laci/releases/download/v1.0.0/Kasir-Laci-v1.0.0-universal.apk) |

> 💡 **Cara Install:** Download APK di atas langsung dari smartphone Android Anda, buka file APK, lalu pilih **Install** (izinkan *Install from unknown sources* pada browser/file manager jika diminta).

---

## Overview & Problem Statement

Micro, Small, and Medium Enterprises (MSMEs / UMKM) in emerging markets operate under unique infrastructural constraints:
1. **Intermittent Connectivity:** Physical retail stalls and traditional markets frequently experience network dead zones where cloud-dependent POS systems stall or fail completely.
2. **Prohibitive SaaS Costs:** Monthly cloud subscription models (\$15–\$45/month) are unsustainable for micro-merchants with thin profit margins.
3. **Hardware Heterogeneity:** Merchants rely on diverse, budget-tier Android hardware with limited memory, diverse screen aspect ratios, and varying Bluetooth peripherals.

**Kasir Laci** solves this by adopting a strict **100% Offline-First architecture**. The application persists all inventory, transaction records, audit logs, and business metrics locally on physical storage via raw SQLite with zero cloud dependencies and zero latency.

---

## Key Engineering Highlights

* **Atomic Transactions & Inventory Rollback:** Implements rigorous `db.transaction()` boundaries in SQLite (`sqflite`) for all checkout flows. Decrements stock levels, generates sales records, and writes itemized invoice entries atomically—guaranteeing rollback on constraint violations and preventing negative stock states or phantom transactions.
* **Deterministic SQLite Schema Migration Engine:** Features an automated versioning pipeline (`v1 -> v2`) with an idempotent `onUpgrade` hook that executes non-destructive schema adjustments (`ALTER TABLE products ADD COLUMN image_path TEXT`) to extend existing production databases without wiping merchant records.
* **Hardware I/O & ESC/POS Thermal Protocol:** Native Bluetooth RFCOMM communication generating raw ESC/POS byte streams tailored for standard 58mm thermal receipt printers. Formats tabular itemization, monetary currency headers, and footers directly on the byte buffer without external cloud print services.
* **Dynamic Adaptive UI Engine:** Employs a custom layout system combining `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisExtent: 250)` with `LayoutBuilder` and `NavigationRail`. Dynamically scales from narrow 340px budget smartphones to full-size tablets, foldables, and desktop POS terminals with zero `RenderFlex` overflows.
* **Offline Camera Barcode Recognition:** Embeds on-device barcode and QR-code vision parsing via Google ML Kit (`mobile_scanner`), achieving sub-100ms barcode lookups directly against indexed SQLite barcode columns without internet access.
* **Binary Size & R8 Optimization:** Hardened ProGuard / R8 code and resource shrinking rules protecting Flutter embedding JNI routines, suppressing Play Core deferred split warnings, and trimming production Google Play App Bundle (`.aab`) download footprints to just **~12–16 MB**.

---

## System Architecture & Data Flow

### Request & Service Flow

```
[ Presentation Layer: Flutter Material 3 (Responsive Adaptive UI) ]
                                │
                                ▼
[ State Layer: Lightweight ChangeNotifier Providers ]
  ├── ProductProvider   (Catalog & Stock Management)
  ├── CartProvider      (In-Memory Real-Time POS Cart)
  ├── SalesProvider     (Checkout Execution & Analytics)
  ├── SettingsProvider  (Store Metadata & Receipt Config)
  └── PrinterProvider   (Bluetooth Thermal Device State)
                                │
                                ▼
[ Database & Hardware Abstraction Layer ]
  │
  ├──► AppDatabase (SQLite Engine)
  │    ├── db.transaction() (ACID Atomic Execution)
  │    ├── Deterministic Schema Migration (v1 -> v2)
  │    └── Indexed Raw SQL Queries (Catalog, Barcode, Range P&L)
  │
  ├──► Hardware I/O Services
  │    ├── Bluetooth Thermal 58mm (ESC/POS Byte Protocol)
  │    ├── Camera Scanner (Google ML Kit Vision Engine)
  │    └── WhatsApp Digital Receipt Dispatcher (Intent URI)
  │
  ▼
[ Local Disk Storage (Application Documents / Raw Database File) ]
```

---

## Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────┐
│            products             │
├─────────────────────────────────┤
│ id           INTEGER PK AUTOINC │
│ name         TEXT NOT NULL      │
│ barcode      TEXT INDEXED       │
│ selling_price INTEGER NOT NULL  │
│ cost_price   INTEGER NOT NULL   │
│ stock        INTEGER NOT NULL   │
│ track_stock  INTEGER NOT NULL   │
│ image_path   TEXT               │
│ created_at   TEXT NOT NULL      │
│ updated_at   TEXT NOT NULL      │
└───────────────┬─────────────────┘
                │ 1
                │
                │ N
┌───────────────▼─────────────────┐       ┌─────────────────────────────────┐
│           sale_items            │       │              sales              │
├─────────────────────────────────┤       ├─────────────────────────────────┤
│ id           INTEGER PK AUTOINC │   N   │ id           INTEGER PK AUTOINC │
│ sale_id      INTEGER NOT NULL FK├───────┤ invoice_number TEXT UNIQUE INDEX │
│ product_id   INTEGER NOT NULL FK│   1   │ total_amount INTEGER NOT NULL   │
│ product_name TEXT NOT NULL      │       │ total_cost   INTEGER NOT NULL   │
│ quantity     INTEGER NOT NULL   │       │ paid_amount  INTEGER NOT NULL   │
│ selling_price INTEGER NOT NULL  │       │ change_amount INTEGER NOT NULL  │
│ cost_price   INTEGER NOT NULL   │       │ payment_method TEXT NOT NULL    │
│ subtotal     INTEGER NOT NULL   │       │ created_at   TEXT NOT NULL      │
└─────────────────────────────────┘       └─────────────────────────────────┘

┌─────────────────────────────────┐
│          store_profile          │
├─────────────────────────────────┤
│ id           INTEGER PK (1)     │
│ name         TEXT NOT NULL      │
│ address      TEXT               │
│ phone        TEXT               │
│ footer_note  TEXT               │
│ qris_path    TEXT               │
│ printer_mac  TEXT               │
└─────────────────────────────────┘
```

---

## Performance & Production Benchmarks

| Metric | Measured Value | Methodology / Notes |
| :--- | :--- | :--- |
| **Play Store Download Footprint** | **~12–16 MB** | Measured via App Bundle Dynamic Split delivery |
| **Split APK (arm64-v8a)** | **26.5 MB** | Direct standalone installation for modern devices |
| **Split APK (armeabi-v7a)** | **22.5 MB** | Standalone installation for legacy 32-bit devices |
| **Cold Start Latency** | **< 1.2s** | Tested on MediaTek Helio G85 (Xiaomi Redmi Note 9) |
| **Active Memory Usage (RAM)** | **~48–64 MB** | Peak usage during continuous camera ML Kit scanning |
| **Network Data Consumption** | **0 KB** | Strictly offline; zero external API or telemetry calls |
| **Automated Test Coverage** | **13/13 (100%)** | Full unit calculation & multi-device widget smoke suite |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # Eye-comfort palette (#F7F7F5 canvas), typography, dimensions
│   ├── database/        # AppDatabase singleton, migrations (v1->v2), indexed schemas
│   └── utils/           # CurrencyFormatter (IDR), DateFormatter, ReceiptHelper
├── models/              # Product, Sale, SaleItem, StoreProfile data entities
├── providers/           # CartProvider, ProductProvider, SalesProvider, PrinterProvider
├── screens/
│   ├── main_navigation_screen.dart # Adaptive Navigation (Bar for mobile / Rail for tablet)
│   ├── splash/          # Animated splash screen with dynamic loading bar
│   ├── pos/             # POS Register, camera scanner, and responsive product grid
│   ├── products/        # Inventory catalog, photo picker (camera/gallery), COGS
│   ├── reports/         # P&L profit calculation, daily/weekly/monthly aggregation
│   └── settings/        # Store profile, Bluetooth printer pairing, DB backup/restore
└── widgets/             # CustomButton, CustomTextField, ProductImageView, SummaryCard
```

---

## Verification & Automated Testing

The codebase includes comprehensive unit tests verifying accounting calculations, currency formatters, and transaction rollback integrity, alongside widget smoke tests validating zero-overflow adaptive rendering:

```bash
# Execute unit and widget test suite
flutter test

# Run static analysis
flutter analyze
```

### Test Suite Summary:
* `calculation_test.dart`: Cart subtotal accuracy, cash change computation, net profit margin (`Total Omzet - Total HPP`), and Indonesian Rupiah formatting.
* `transaction_rollback_test.dart`: Schema upgrade verification (`v1 -> v2`) and atomic database rollback execution upon stock depletion.
* `main_navigation_smoke_test.dart`: Full UI rendering across **360x800 mobile**, **800x1280 tablet**, and dynamic window resizing without layout overflows.

---

## Getting Started

### Prerequisites
* Flutter SDK (3.24.x or latest stable)
* Android Studio / VS Code with Dart & Flutter extensions
* Android Device or Emulator (API 23+)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ntraphouseee/kasir-laci.git
   cd kasir-laci
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   # Run in release mode on connected device
   flutter run --release
   ```

### Production Build

```bash
# Build Android App Bundle for Google Play Store upload (~12-16 MB target delivery)
flutter build appbundle --release

# Build architecture-split APKs for direct distribution
flutter build apk --release --split-per-abi
```

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
