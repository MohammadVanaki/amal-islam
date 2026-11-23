import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/main_tab_app_bar.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  int _selectedTabIndex = 0; // 0: السيرة الذاتية (افتراضي), 1: حول التطبيق

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPalette = ref.watch(appPaletteProvider);

    return Scaffold(
      appBar: MainTabAppBar(
        title: _selectedTabIndex == 0 ? 'السيرة الذاتية' : 'حول التطبيق',
        icon: _selectedTabIndex == 0
            ? Icons.history_edu_rounded
            : Icons.info_outline_rounded,
      ),
      body: Column(
        children: [
          // Elegant Tab Selector (السيرة الذاتية على اليمين وافتراضية)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardDark
                    : currentPalette.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : currentPalette.color.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'السيرة الذاتية',
                      icon: Icons.history_edu_rounded,
                      index: 0,
                      currentPalette: currentPalette,
                      isDark: isDark,
                    ),
                  ),
                  const Gap(6),
                  Expanded(
                    child: _buildTabButton(
                      title: 'حول التطبيق',
                      icon: Icons.info_outline_rounded,
                      index: 1,
                      currentPalette: currentPalette,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _selectedTabIndex == 0
                  ? _buildBiographyTab(context, currentPalette, isDark)
                  : _buildAboutAppTab(context, currentPalette, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
    required AppPalette currentPalette,
    required bool isDark,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedTabIndex != index) {
          setState(() {
            _selectedTabIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9.5),
        decoration: BoxDecoration(
          color: isSelected ? currentPalette.color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentPalette.color.withValues(alpha: 0.32),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6B7280)),
            ),
            const Gap(6),
            Text(
              title,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: حول التطبيق (Original Content)
  // ==========================================
  Widget _buildAboutAppTab(
    BuildContext context,
    AppPalette currentPalette,
    bool isDark,
  ) {
    return ListView(
      key: const ValueKey<int>(0),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        // App Logo Hero
        Center(
          child: Column(
            children: [
              SizedBox(
                width: 90,
                height: 90,
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
              const Gap(12),
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: currentPalette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentPalette.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'بقلم: الكاتبة أمل الموسوي',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: currentPalette.accent,
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: currentPalette.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(22),

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
                textAlign: TextAlign.justify,
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
                subtitle:
                    'الاستفادة من سرعة البحث في النص وإمكانية تصفح النسخة الأصلية المصورة',
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
                subtitle:
                    'الوضع الورقي (سيبيا)، والوضع الليلي، والوضع النهاري مع التحكم بحجم الخط',
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
    );
  }

  // ==========================================
  // TAB 2: السيرة الذاتية للكاتبة أمل الموسوي
  // ==========================================
  Widget _buildBiographyTab(
    BuildContext context,
    AppPalette currentPalette,
    bool isDark,
  ) {
    return ListView(
      key: const ValueKey<int>(1),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        // Author Profile Header
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: currentPalette.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const Gap(14),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      currentPalette.color.withValues(alpha: 0.2),
                      currentPalette.color.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentPalette.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: currentPalette.color,
                    size: 34,
                  ),
                ),
              ),
              const Gap(12),
              Text(
                'الكاتبة أمل الموسوي',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : currentPalette.color,
                ),
              ),
              const Gap(4),
              Text(
                'كاتبة وباحثة إسلامية معاصرة تقيم في النجف الأشرف',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBioChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'ولدت ببغداد سنة ١٩٦٤م',
                    palette: currentPalette,
                    isDark: isDark,
                  ),
                  _buildBioChip(
                    icon: Icons.account_balance_rounded,
                    label: 'أسرة المقدس الغريفي الموسوي',
                    palette: currentPalette,
                    isDark: isDark,
                  ),
                  _buildBioChip(
                    icon: Icons.location_on_rounded,
                    label: 'النجف الأشرف',
                    palette: currentPalette,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(16),

        // Section 1: النشأة والنسب العلمي
        _buildBioSectionCard(
          context: context,
          palette: currentPalette,
          isDark: isDark,
          title: 'النشأة والنسب العلمي',
          icon: Icons.family_restroom_rounded,
          content:
              'ولدت الكاتبة في بغداد سنة ١٩٦٤م، وهي علوية الأبوين من أسرة علمية دينية هي أسرة «المقدس الغريفي الموسوي»؛ وهي أسرة معروفة بكثرة العلماء والمفكرين فيها والذين خدموا الدين ومذهب أمير المؤمنين عبر أجيال كثيرة. وأمها من السادة آل الصافي في النجف الأشرف.\n\n'
              'فكانت نشأتها وتربيتها في أحضان هذه الأسرة العلوية الطيبة، وتلقت الدروس الدينية عند والدها الشهيد العلامة السيد محسن المقدس الغريفي فدرست عنده المنطق وأصول المظفر؛ فكان للأسرة من جهة وللجهد والمثابرة الفردية من جهة أخرى الأثر الكبير في صقل الشخصية العلمية والمواهب الفكرية عند الكاتبة.',
        ),
        const Gap(16),

        // Section 2: المسيرة والروح الرسالية
        _buildBioSectionCard(
          context: context,
          palette: currentPalette,
          isDark: isDark,
          title: 'المسيرة الواعية والروح الرسالية',
          icon: Icons.psychology_rounded,
          content:
              'عاصرت الكاتبة منذ أوائل نشوئها الحركات الإسلامية الكبرى في العراق والمنطقة، وعلى رأسها الحركة الفكرية الواعية في العراق بقيادة السيد الشهيد السعيد محمد باقر الصدر (قدس سره)، وكذلك الحركة الإسلامية في إيران بقيادة السيد الخميني (قدس سره)؛ فكانت بوجدانها وشعورها تواكب تلك الحركات الإسلامية وتستمد منها الجذوة التي ألهبت فيها الروح الرسالية.\n\n'
              'وكانت تلك الروح الرسالية هي الدافع لها لكي تسير على خطى الرسل والعلماء الرساليين في تغيير العادات الاجتماعية السيئة وتصحيح الانحرافات الاجتماعية التي سادت في المجتمع قديماً وحديثاً، فاستشعرت المسؤولية في محاربة تلك العادات وتلك الانحرافات التي كان سببها أعداء دين الإنسانية ودين الحياة، الدين الإسلامي الذي كان مقرراً له أن يجعل الإنسان في قمة السعادة في حياته الدنيا وفي حياته الباقية.',
        ),
        const Gap(16),

        // Section 3: المنهج التربوي والأسلوب
        _buildBioSectionCard(
          context: context,
          palette: currentPalette,
          isDark: isDark,
          title: 'المنهج التربوي واللغة الميسرة',
          icon: Icons.menu_book_rounded,
          content:
              'كانت كتبها ومؤلفاتها رسائل واضحة وسهلة وبمتناول أفهام الناس جميعاً، فكانت اللغة التي كتبت بها لغة سهلة يستسيغها الجميع، ولم تتعدَّ فيما كتبته روح الشريعة السمحاء وتعاليمها الغراء؛ فكانت مواضيعها هي في روحها معانٍ جاء بها الكتاب الكريم وأحاديث أهل بيت النبوة، لذلك كان لها المقبولية والتأثير بفضل الله تعالى.\n\n'
              'واتسمت مؤلفات الكاتبة بالطابع الاجتماعي والتربوي حيث تناولت قضايا الأسرة والزواج وتربية الطفل ومعالجة الظواهر المنحرفة في المجتمع مستلهمة الحلول من النماذج البشرية الأكمل وهم أهل بيت النبوة (صلوات الله عليهم أجمعين)؛ ونحت في كتبها ذلك المنحى ووسمتها بتلك السمة لما رأت من حاجة لمثل تلك المواضيع.\n\n'
              'وقد ترجمت بعض الجامعات الإيرانية بعض كتبها إلى اللغة الفارسية لتوزيعها على الطالبات تعميماً للفائدة وترسيخاً للقيم الأسرية الإسلامية.',
        ),
        const Gap(16),

        // Section 4: قائمة الكتب
        _buildWorksListCard(
          context: context,
          palette: currentPalette,
          isDark: isDark,
          title: 'مؤلفاتها: الكتب',
          subtitle: '١٥ مؤلفاً فكرياً وتربوياً مطبوعاً',
          icon: Icons.library_books_rounded,
          items: const [
            'الأربعون حديثاً من مدرسة الزهراء',
            'العفة رأس كل خير',
            'غضوا أبصاركم ترون العجائب',
            'التزويج أفضل بناء في الإسلام',
            'النهضة الحسينية رؤى جديدة',
            'الإمام علي عليه السلام مواجهة الإنحراف',
            'الإمام الصادق عليه السلام في مواجهة الإنحراف',
            'رحلة الهدى في سيرة بنت الهدى',
            'الصدق رأس الإسلام',
            'الدين هو الحب',
            'الإخلاص وبلوغ الآمال',
            'بالتواضع تتم النعمة',
            'الخطابة النسائية بين الواقع والطموح',
            'دلائل العفة في القرآن الكريم',
            'الشكر وزيادة النعمة',
          ],
        ),
        const Gap(16),

        // Section 5: قائمة الكراريس
        _buildWorksListCard(
          context: context,
          palette: currentPalette,
          isDark: isDark,
          title: 'مؤلفاتها: الكراريس التربوية',
          subtitle: 'سلسلة إضاءات إسلامية في التربية الأسرية ونماذج أخرى',
          icon: Icons.collections_bookmark_rounded,
          items: const [
            'مجموعة إضاءات إسلامية في التربية الأسرية (مجموعة كبيرة من الكراريس بعناوين تربوية متنوعة)',
            'رقص النساء في الأعراس مرتع الشيطان',
            'قبسات من الأسوة الفاطمية',
            'إشراقات فاطمية في التربية',
            'الفتيات بين الدراسة والزواج',
            'النجاة في ولاية علي',
            'الأخلاق وارتقاء الجامعات',
            'رفقاً بالرجال يا قوارير',
          ],
        ),
        const Gap(24),

        // Bio Footer
        Center(
          child: Text(
            'نسأل الله تعالى للكاتبة دوام التوفيق والتسديد في خدمة الدين والمجتمع',
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioChip({
    required IconData icon,
    required String label,
    required AppPalette palette,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: palette.color.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.color),
          const Gap(5),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : palette.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSectionCard({
    required BuildContext context,
    required AppPalette palette,
    required bool isDark,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
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
            color: palette.color.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: palette.color, size: 16),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13.5,
              height: 1.85,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorksListCard({
    required BuildContext context,
    required AppPalette palette,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
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
            color: palette.color.withValues(alpha: 0.04),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: palette.accent, size: 17),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 15,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: palette.color,
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          ...items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            final isLast = index == items.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: palette.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: palette.color,
                            ),
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          item,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 8,
                    thickness: 0.6,
                    color: isDark
                        ? AppColors.borderDark.withValues(alpha: 0.5)
                        : AppColors.borderLight,
                  ),
              ],
            );
          }),
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
