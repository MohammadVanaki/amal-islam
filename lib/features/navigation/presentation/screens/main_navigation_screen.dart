import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../about/presentation/screens/about_screen.dart';
import '../../../library/presentation/screens/categories_screen.dart';
import '../../../library/presentation/screens/downloaded_books_screen.dart';
import '../../../library/presentation/screens/library_home_screen.dart';
import '../../../library/providers/download_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const LibraryHomeScreen(),
    const CategoriesScreen(),
    DownloadedBooksScreen(
      onBrowseBooks: () {
        setState(() {
          _currentIndex = 0;
        });
      },
    ),
    const AboutScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPalette = ref.watch(appPaletteProvider);
    final downloadedBooksAsync = ref.watch(downloadedBooksProvider);
    final downloadCount = downloadedBooksAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: currentPalette.color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. الرئيسية
                _buildNavItem(
                  index: 0,
                  label: 'الرئيسية',
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  activeColor: currentPalette.color,
                  isDark: isDark,
                ),

                // 2. التصانيف
                _buildNavItem(
                  index: 1,
                  label: 'التصانيف',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  activeColor: currentPalette.color,
                  isDark: isDark,
                ),

                // 3. الكتب المحملة (فلوتینگ)
                _buildFloatingNavItem(
                  index: 2,
                  label: 'الكتب المحملة',
                  currentPalette: currentPalette,
                  isDark: isDark,
                  downloadCount: downloadCount,
                ),

                // 4. حول التطبيق
                _buildNavItem(
                  index: 3,
                  label: 'حول التطبيق',
                  icon: Icons.info_outline_rounded,
                  activeIcon: Icons.info_rounded,
                  activeColor: currentPalette.color,
                  isDark: isDark,
                ),

                // 5. الاعدادات
                _buildNavItem(
                  index: 4,
                  label: 'الاعدادات',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  activeColor: currentPalette.color,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.25 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? activeColor : Colors.grey,
                  size: 23,
                ),
              ),
              const Gap(3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : activeColor)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required String label,
    required AppPalette currentPalette,
    required bool isDark,
    required int downloadCount,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Button Elevated Circle
            Transform.translate(
              offset: const Offset(0, -14),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          currentPalette.primaryLight,
                          currentPalette.color,
                        ],
                      ),
                      border: Border.all(
                        color: isSelected
                            ? currentPalette.accent
                            : Colors.white.withValues(alpha: isDark ? 0.35 : 0.6),
                        width: isSelected ? 2.6 : 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? currentPalette.accent.withValues(alpha: 0.5)
                              : currentPalette.color.withValues(alpha: 0.35),
                          blurRadius: isSelected ? 14 : 9,
                          spreadRadius: isSelected ? 1 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected
                              ? Icons.download_done_rounded
                              : Icons.cloud_download_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Download Count Badge
                  if (downloadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: currentPalette.accent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$downloadCount',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.black,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Label
            Transform.translate(
              offset: const Offset(0, -10),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : currentPalette.color)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
