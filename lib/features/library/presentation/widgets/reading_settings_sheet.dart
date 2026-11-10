import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../providers/reader_settings_provider.dart';

class ReadingSettingsSheet extends ConsumerWidget {
  const ReadingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);
    final currentPalette = ref.watch(appPaletteProvider);
    final selectionColor = currentPalette.color;

    return Material(
      color: settings.backgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      elevation: 16,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Gap(14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_rounded, color: selectionColor, size: 22),
                      const Gap(8),
                      Text(
                        'إعدادات القراءة',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // 1. Theme Color Palettes (أنماط العرض والألوان الأربعة)
              Text(
                'نمط العرض والألوان',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Gap(10),
              Row(
                children: [
                  _buildThemeCard(
                    settings: settings,
                    selectionColor: selectionColor,
                    title: 'نهاري',
                    subtitle: 'أبيض',
                    isSelected: settings.themeMode == ReaderThemeMode.day,
                    bgColor: const Color(0xFFFFFFFF),
                    textColor: const Color(0xFF1E2224),
                    borderColor: Colors.grey.shade300,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setThemeMode(ReaderThemeMode.day);
                    },
                  ),
                  const Gap(8),
                  _buildThemeCard(
                    settings: settings,
                    selectionColor: selectionColor,
                    title: 'سيبيا',
                    subtitle: 'ورق كلاسيكي',
                    isSelected: settings.themeMode == ReaderThemeMode.sepia,
                    bgColor: const Color(0xFFFAF3E3),
                    textColor: const Color(0xFF453422),
                    borderColor: const Color(0xFFDCCBB5),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setThemeMode(ReaderThemeMode.sepia);
                    },
                  ),
                  const Gap(8),
                  _buildThemeCard(
                    settings: settings,
                    selectionColor: selectionColor,
                    title: 'رمادي',
                    subtitle: 'مريح للعين',
                    isSelected: settings.themeMode == ReaderThemeMode.softGray,
                    bgColor: const Color(0xFFE8EAEB),
                    textColor: const Color(0xFF22272A),
                    borderColor: const Color(0xFFC5C9CE),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setThemeMode(ReaderThemeMode.softGray);
                    },
                  ),
                  const Gap(8),
                  _buildThemeCard(
                    settings: settings,
                    selectionColor: selectionColor,
                    title: 'ليلي',
                    subtitle: 'داكن OLED',
                    isSelected: settings.themeMode == ReaderThemeMode.night,
                    bgColor: const Color(0xFF101312),
                    textColor: const Color(0xFFE0E5E3),
                    borderColor: const Color(0xFF273330),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.setThemeMode(ReaderThemeMode.night);
                    },
                  ),
                ],
              ),
              const Gap(20),

              // 2. Reading View Mode (تقليب أفقي مقابل تمرير متواصل)
              Text(
                'طريقة عرض الصفحات',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Gap(10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildViewModeButton(
                        context: context,
                        settings: settings,
                        selectionColor: selectionColor,
                        title: 'تقليب أفقي',
                        subtitle: 'صفحات الكتاب',
                        icon: Icons.auto_stories_rounded,
                        isSelected: settings.viewMode == ReaderViewMode.horizontalPage,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setViewMode(ReaderViewMode.horizontalPage);
                        },
                      ),
                    ),
                    const Gap(6),
                    Expanded(
                      child: _buildViewModeButton(
                        context: context,
                        settings: settings,
                        selectionColor: selectionColor,
                        title: 'تمرير متواصل',
                        subtitle: 'تمرير عمودي',
                        icon: Icons.view_day_rounded,
                        isSelected: settings.viewMode == ReaderViewMode.verticalScroll,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setViewMode(ReaderViewMode.verticalScroll);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // 3. Font Family Selection (اختيار نوع الخط)
              Text(
                'نوع الخط',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Gap(10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ReaderFontFamily.values.map((font) {
                    final isSelected = settings.fontFamily == font;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          font.displayName,
                          style: TextStyle(
                            fontFamily: font.fontFamilyName,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: selectionColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? selectionColor : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            notifier.setFontFamily(font);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Gap(20),

              // 4. Font Size Slider with A- / A+ buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'حجم الخط',
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${settings.fontSize.toInt()} نقطة',
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, color: selectionColor),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: selectionColor.withValues(alpha: 0.12),
                      foregroundColor: selectionColor,
                    ),
                    icon: const Text('A-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    tooltip: 'تصغير الخط',
                    onPressed: settings.fontSize > 14
                        ? () {
                            HapticFeedback.lightImpact();
                            notifier.setFontSize(settings.fontSize - 1);
                          }
                        : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: selectionColor,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                        thumbColor: selectionColor,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: settings.fontSize,
                        min: 14,
                        max: 32,
                        divisions: 18,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          notifier.setFontSize(val);
                        },
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: selectionColor.withValues(alpha: 0.12),
                      foregroundColor: selectionColor,
                    ),
                    icon: const Text('A+', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    tooltip: 'تكبير الخط',
                    onPressed: settings.fontSize < 32
                        ? () {
                            HapticFeedback.lightImpact();
                            notifier.setFontSize(settings.fontSize + 1);
                          }
                        : null,
                  ),
                ],
              ),
              const Gap(14),

              // 5. Line Height Slider with - / + buttons (تباعد الأسطر)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تباعد الأسطر',
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${settings.lineHeight.toStringAsFixed(1)}x',
                    style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold, color: selectionColor),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: selectionColor.withValues(alpha: 0.12),
                      foregroundColor: selectionColor,
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    tooltip: 'تقليل تباعد الأسطر',
                    onPressed: settings.lineHeight > 1.5
                        ? () {
                            HapticFeedback.lightImpact();
                            final newVal = (settings.lineHeight - 0.1).clamp(1.5, 2.8);
                            notifier.setLineHeight(double.parse(newVal.toStringAsFixed(1)));
                          }
                        : null,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: selectionColor,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
                        thumbColor: selectionColor,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: settings.lineHeight,
                        min: 1.5,
                        max: 2.8,
                        divisions: 13,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          notifier.setLineHeight(val);
                        },
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: selectionColor.withValues(alpha: 0.12),
                      foregroundColor: selectionColor,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    tooltip: 'زيادة تباعد الأسطر',
                    onPressed: settings.lineHeight < 2.8
                        ? () {
                            HapticFeedback.lightImpact();
                            final newVal = (settings.lineHeight + 0.1).clamp(1.5, 2.8);
                            notifier.setLineHeight(double.parse(newVal.toStringAsFixed(1)));
                          }
                        : null,
                  ),
                ],
              ),
              const Gap(10),

              // 6. Keep Screen Awake Switch (إبقاء الشاشة مضاءة)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  settings.keepScreenAwake ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                  color: settings.keepScreenAwake ? selectionColor : Colors.grey,
                ),
                title: Text(
                  'إبقاء الشاشة مضاءة',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'منع قفل الشاشة التلقائي أثناء المطالعة',
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 11.5, color: Colors.grey),
                ),
                value: settings.keepScreenAwake,
                activeColor: selectionColor,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  notifier.setKeepScreenAwake(val);
                },
              ),
              const Gap(12),

              // 7. Live Preview Box (معاينة حية)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: settings.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: settings.themeMode == ReaderThemeMode.night
                        ? const Color(0xFF273330)
                        : Colors.grey.shade400.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: settings.fontFamily.fontFamilyName,
                        color: settings.quranColor,
                        fontSize: (settings.fontSize * 1.1).clamp(16.0, 34.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '«الصدقُ رأس الإيمان وزين الإنسان»\nنموذج لمعاينة نص القراءة بالخط والتباعد والنمط المختار.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: settings.fontFamily.fontFamilyName,
                        color: settings.textColor,
                        fontSize: settings.fontSize,
                        height: settings.lineHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required ReaderSettingsState settings,
    required Color selectionColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? selectionColor : borderColor,
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectionColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? selectionColor : textColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              const Gap(6),
              Text(
                title,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: textColor.withValues(alpha: 0.65),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required BuildContext context,
    required ReaderSettingsState settings,
    required Color selectionColor,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectionColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.75)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
