import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/main_tab_app_bar.dart';
import '../../../auth/presentation/widgets/auth_dialog.dart';
import '../../../library/providers/download_provider.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'تطبيق مكتبة أمل الإسلام 📚✨\n'
      'سلسلة إضاءات إسلامية في التربية الأسرية بقلم الكاتبة أمل الموسوي.\n'
      'تصفح واقرأ الكتب بدون الحاجة إلى إنترنت مع محرك بحث كامل وتنسيق مريح للعين:\n'
      'https://play.google.com/store/apps/details?id=com.dijlah.alamalislam',
      subject: 'مكتبة أمل الإسلام',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(appPaletteProvider);
    final totalBytesAsync = ref.watch(totalStorageBytesProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ordered right-to-left in RTL to match user screenshot:
    // [Emerald (selected), Cyan, Bronze, Slate, Navy]
    final palettesInOrder = [
      AppPalette.emerald,
      AppPalette.cyan,
      AppPalette.bronze,
      AppPalette.slate,
      AppPalette.navy,
    ];

    return Scaffold(
      appBar: MainTabAppBar(
        title: 'الإعدادات',
        icon: Icons.tune_rounded,
        badge: TabAppBarBadge(
          icon: Icons.palette_rounded,
          label: currentPalette.name,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // 1. Top App Header Card (مطابق کامپوننت بالای اسکرین‌شات کاربر)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [AppColors.cardDark, AppColors.surfaceDark]
                    : [
                        currentPalette.color.withValues(alpha: 0.12),
                        currentPalette.color.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: currentPalette.color.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentPalette.color.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // App Icon on the right in RTL
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset(
                    'assets/image/appIcon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: currentPalette.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const Gap(14),
                // App Title & Version Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'مكتبة أمل الاسلام',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF151817),
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: currentPalette.color.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentPalette.color.withValues(
                                  alpha: 0.35,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              packageInfoAsync.maybeWhen(
                                data: (info) => 'v${info.version}',
                                orElse: () => 'v2.0.0',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? currentPalette.primaryLight
                                    : currentPalette.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Text(
                        'سلسلة اضاءات إسلامية في التربية الأسرية',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // User Account & Cloud Sync Card (Firebase Auth & Firestore)
          _buildUserAccountCard(context, ref, currentPalette, isDark),
          const Gap(16),

          // 2. Theme Colors Card ("ألوان المظهر" - دقیقاً مطابق اسکرین‌شات کاربر)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentPalette.color.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Palette Icon on right, Title & Subtitle)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentPalette.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: currentPalette.color,
                        size: 22,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ألوان المظهر',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF151817),
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'اختر النمط اللوني المناسب لواجهة التطبيق',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Inner Rounded Swatches Container (نوار گرد کانتینر دایره‌های رنگ)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF6F8F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFEBEFEB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: palettesInOrder.map((palette) {
                      final isSelected = currentPalette == palette;

                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(appPaletteProvider.notifier)
                              .setPalette(palette);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              width: isSelected ? 48 : 40,
                              height: isSelected ? 48 : 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: palette.color,
                                        width: 2.4,
                                      )
                                    : null,
                              ),
                              padding: EdgeInsets.all(isSelected ? 3.5 : 0.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: palette.color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.color.withValues(
                                        alpha: isSelected ? 0.35 : 0.15,
                                      ),
                                      blurRadius: isSelected ? 6 : 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // 3. Share App Card
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentPalette.color.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => _shareApp(context),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                      ),
                      const Gap(14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مشاركة التطبيق',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Gap(2),
                            Text(
                              'إرسال رابط التطبيق إلى الأصدقاء والعائلة',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),

          // 5. Storage & Cache
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_special_rounded,
                          color: currentPalette.color,
                          size: 20,
                        ),
                        const Gap(10),
                        const Text(
                          'حجم الكتب المحمّلة',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatBytes(totalBytesAsync.valueOrNull ?? 0),
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: currentPalette.color,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                const Divider(),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مسح الذاكرة المؤقتة للصور',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        PaintingBinding.instance.imageCache.clear();
                        PaintingBinding.instance.imageCache.clearLiveImages();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تنظيف الذاكرة المؤقتة بنجاح'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.cleaning_services_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'تنظيف',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(24),

          // Dynamic Version & Build Info
          Center(
            child: packageInfoAsync.maybeWhen(
              data: (info) => Text(
                'الإصدار ${info.version} (بناء ${info.buildNumber})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }

  Widget _buildUserAccountCard(
    BuildContext context,
    WidgetRef ref,
    AppPalette currentPalette,
    bool isDark,
  ) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: currentPalette.color.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: user != null
          ? Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: currentPalette.color.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    color: currentPalette.color,
                    size: 24,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName != null &&
                                      user.displayName!.isNotEmpty
                                  ? user.displayName!
                                  : 'المستخدم',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_done_rounded,
                                  color: Colors.green,
                                  size: 12,
                                ),
                                Gap(4),
                                Text(
                                  'متصل',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(2),
                      Text(
                        user.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: const Text('تسجيل الخروج'),
                        content: const Text(
                          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('تسجيل الخروج'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authServiceProvider).signOut();
                    }
                  },
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: currentPalette.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    color: currentPalette.color,
                    size: 24,
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الحساب والمزامنة السحابية',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'سجل دخولك لحفظ قراءاتك وملاحظاتك سحابياً',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                ElevatedButton(
                  onPressed: () => AuthDialog.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPalette.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'دخول',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
