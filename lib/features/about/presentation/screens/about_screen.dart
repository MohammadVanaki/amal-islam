import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/main_tab_app_bar.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPalette = ref.watch(appPaletteProvider);

    return Scaffold(
      appBar: const MainTabAppBar(
        title: 'حول التطبيق',
        icon: Icons.info_outline_rounded,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // App Logo Hero
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset(
                    'assets/image/appIcon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: currentPalette.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: currentPalette.accent,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const Gap(14),
                Text(
                  'مكتبة أمل الاسلام',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : currentPalette.color,
                  ),
                ),
                const Gap(4),
                Text(
                  'سلسلة إضاءات إسلامية في التربية الأسرية',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: currentPalette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentPalette.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'بقلم: الكاتبة أمل الموسوي',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: currentPalette.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),

          // About the Project Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: currentPalette.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'رسالة وأهداف المكتبة',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                Text(
                  'تعد مكتبة «أمل الإسلام» نافذة معرفية وتربوية تهدف إلى تعزيز الثقافة الأسرية المستمدة من الهدي القرآني ومنهج أهل البيت عليهم السلام.\n\n'
                  'تسعى هذه السلسلة التربوية إلى معالجة الإشكاليات السلوكية والاجتماعية التي تواجه الأسرة المعاصرة، وتقديم حلول علمية وعملية لبناء جيل مؤمن وواعٍ.',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13.5,
                    height: 1.8,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Features List
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: currentPalette.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'مزايا التطبيق الإلكتروني',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                _buildFeatureRow(
                  palette: currentPalette,
                  icon: Icons.offline_pin_rounded,
                  title: 'قراءة دون اتصال بالإنترنت',
                  subtitle: 'تحميل الكتب وقراءتها في أي وقت دون الحاجة للشبكة',
                ),
                const Divider(height: 20),
                _buildFeatureRow(
                  palette: currentPalette,
                  icon: Icons.integration_instructions_rounded,
                  title: 'دعم ثنائي (نص رقمي + PDF مصور)',
                  subtitle: 'الاستفادة من سرعة البحث في النص وإمكانية تصفح النسخة الأصلية المصورة',
                ),
                const Divider(height: 20),
                _buildFeatureRow(
                  palette: currentPalette,
                  icon: Icons.bookmark_add_rounded,
                  title: 'الإشارات المرجعية والتمييز والملاحظات',
                  subtitle: 'حفظ الصفحات المفضلة وتسجيل الخواطر والفوائد',
                ),
                const Divider(height: 20),
                _buildFeatureRow(
                  palette: currentPalette,
                  icon: Icons.menu_book_rounded,
                  title: 'أنماط قراءة مريحة للعين',
                  subtitle: 'الوضع الورقي (سيبيا)، والوضع الليلي، والوضع النهاري مع التحكم بحجم الخط',
                ),
              ],
            ),
          ),
          const Gap(16),

          // Share button in about
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [currentPalette.primaryLight, currentPalette.color],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: currentPalette.color.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  'تطبيق مكتبة أمل الإسلام 📚✨\n'
                  'سلسلة إضاءات إسلامية في التربية الأسرية بقلم الكاتبة أمل الموسوي.\n'
                  'https://play.google.com/store/apps/details?id=com.dijlah.alamalislam',
                  subject: 'مكتبة أمل الإسلام',
                );
              },
              icon: Icon(
                Icons.share_rounded,
                color: currentPalette.accent,
                size: 20,
              ),
              label: Text(
                'مشاركة التطبيق مع الأهل والأصدقاء',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Gap(20),

          // Footer
          Center(
            child: Text(
              'جميع الحقوق محفوظة لمكتبة أمل الإسلام ©',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required AppPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: palette.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: palette.primaryLight),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(2),
              Text(
                subtitle,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
