import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

class MainTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final Widget? badge;
  final List<Widget>? extraActions;

  const MainTabAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.badge,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 62.0,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDark
                  : currentPalette.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : currentPalette.color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: currentPalette.color,
                size: 20,
              ),
            ),
          ),
          const Gap(10),
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : currentPalette.color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        if (badge != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: badge),
          ),
        ...?extraActions,
      ],
    );
  }
}

class TabAppBarBadge extends ConsumerWidget {
  final IconData icon;
  final String label;

  const TabAppBarBadge({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: currentPalette.color.withValues(
          alpha: isDark ? 0.25 : 0.08,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: currentPalette.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: currentPalette.color,
          ),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : currentPalette.color,
            ),
          ),
        ],
      ),
    );
  }
}

