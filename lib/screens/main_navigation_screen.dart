import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimens.dart';
import '../core/constants/app_styles.dart';
import '../providers/settings_provider.dart';
import 'pos/pos_screen.dart';
import 'products/product_list_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

/// Layar Navigasi Utama Aplikasi
/// Terdiri dari tepat 4 Tab: Kasir, Barang, Laporan, Pengaturan
/// Sesuai panduan Boomer-friendly: teks eksplisit + ikon, ukuran besar.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadProfile();
    });
  }

  final List<Widget> _screens = const [
    PosScreen(),
    ProductListScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 720;

        if (isWideScreen) {
          // Tampilan Tablet / Foldable Terbuka / Desktop: Navigation Rail di Samping Kiri
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  minWidth: 88,
                  backgroundColor: AppColors.surface,
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primary,
                    size: 28,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                  selectedLabelTextStyle: AppStyles.badgeText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  unselectedLabelTextStyle: AppStyles.badgeText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.point_of_sale_outlined),
                      selectedIcon: Icon(Icons.point_of_sale),
                      label: Text('Kasir'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Barang'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Laporan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Pengaturan'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Tampilan Smartphone Standar: Bottom Navigation Bar
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border,
                  width: AppDimens.borderWidth,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                height: 68, // Oversized Touch Targets
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: 'Kasir',
                      icon: Icons.point_of_sale_outlined,
                      activeIcon: Icons.point_of_sale,
                    ),
                    _buildNavItem(
                      index: 1,
                      label: 'Barang',
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2,
                    ),
                    _buildNavItem(
                      index: 2,
                      label: 'Laporan',
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                    ),
                    _buildNavItem(
                      index: 3,
                      label: 'Pengaturan',
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 26,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppStyles.badgeText.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
