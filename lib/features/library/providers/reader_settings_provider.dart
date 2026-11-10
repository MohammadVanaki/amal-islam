import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum ReaderThemeMode {
  day, // تم روز / سفید
  night, // تم شب / OLED تاریک
  sepia, // تم سپیا / کاغذ کهن
  softGray, // تم خاکستری نرم / ضد بازتاب
}

enum ReaderViewMode {
  horizontalPage, // ورق‌زدن افقی (PageView)
  verticalScroll, // پیمایش پیوسته عمودی (Continuous Scroll)
}

enum ReaderFontFamily {
  amiri, // امیری (خط عثمان طه)
  scheherazadeNew, // شهرزاد (نسخ روان)
  cairo, // قاهره (مدرن و خوانا)
  lateef, // لطیف (سنتی)
  system, // پیش‌فرض سیستم
}

extension ReaderFontFamilyExtension on ReaderFontFamily {
  String get displayName {
    switch (this) {
      case ReaderFontFamily.amiri:
        return 'الأميري (عثمان طه)';
      case ReaderFontFamily.scheherazadeNew:
        return 'شهرزاد (نسخ)';
      case ReaderFontFamily.cairo:
        return 'القاهرة (حديث)';
      case ReaderFontFamily.lateef:
        return 'لطيف (تقليدي)';
      case ReaderFontFamily.system:
        return 'افتراضي النظام';
    }
  }

  String? get fontFamilyName {
    try {
      switch (this) {
        case ReaderFontFamily.amiri:
          return GoogleFonts.amiri().fontFamily;
        case ReaderFontFamily.scheherazadeNew:
          return GoogleFonts.scheherazadeNew().fontFamily;
        case ReaderFontFamily.cairo:
          return GoogleFonts.cairo().fontFamily;
        case ReaderFontFamily.lateef:
          return GoogleFonts.lateef().fontFamily;
        case ReaderFontFamily.system:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

class ReaderSettingsState {
  final ReaderThemeMode themeMode;
  final ReaderViewMode viewMode;
  final ReaderFontFamily fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool keepScreenAwake;

  const ReaderSettingsState({
    this.themeMode = ReaderThemeMode.sepia,
    this.viewMode = ReaderViewMode.verticalScroll,
    this.fontFamily = ReaderFontFamily.amiri,
    this.fontSize = 18.0,
    this.lineHeight = 1.9,
    this.keepScreenAwake = false,
  });

  // --- Theme Colors ---
  Color get backgroundColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFFFFFFFF);
      case ReaderThemeMode.night:
        return const Color(0xFF101312); // Deep OLED dark
      case ReaderThemeMode.sepia:
        return const Color(0xFFFAF3E3); // Warm parchment
      case ReaderThemeMode.softGray:
        return const Color(0xFFE8EAEB); // Matte soft gray
    }
  }

  Color get textColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF1E2224);
      case ReaderThemeMode.night:
        return const Color(0xFFE0E5E3);
      case ReaderThemeMode.sepia:
        return const Color(0xFF453422);
      case ReaderThemeMode.softGray:
        return const Color(0xFF22272A);
    }
  }

  Color get cardColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFFF6F8F7);
      case ReaderThemeMode.night:
        return const Color(0xFF19201E);
      case ReaderThemeMode.sepia:
        return const Color(0xFFF1E4CE);
      case ReaderThemeMode.softGray:
        return const Color(0xFFDCE0E3);
    }
  }

  Color get appBarColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF0E382F);
      case ReaderThemeMode.night:
        return const Color(0xFF141E1B);
      case ReaderThemeMode.sepia:
        return const Color(0xFFEDE0C7);
      case ReaderThemeMode.softGray:
        return const Color(0xFFD3D7DB);
    }
  }

  Color get appBarTextColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return Colors.white;
      case ReaderThemeMode.night:
        return Colors.white;
      case ReaderThemeMode.sepia:
        return const Color(0xFF453422);
      case ReaderThemeMode.softGray:
        return const Color(0xFF22272A);
    }
  }

  Color get headingColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF987116);
      case ReaderThemeMode.night:
        return const Color(0xFFE5BE53);
      case ReaderThemeMode.sepia:
        return const Color(0xFF987116);
      case ReaderThemeMode.softGray:
        return const Color(0xFF7F5D13);
    }
  }

  String get headingColorHex {
    return _toHex(headingColor);
  }

  Color get quranColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF0D7A3E);
      case ReaderThemeMode.night:
        return const Color(0xFF4CAF50);
      case ReaderThemeMode.sepia:
        return const Color(0xFF176337);
      case ReaderThemeMode.softGray:
        return const Color(0xFF0D7A3E);
    }
  }

  String get quranColorHex {
    return _toHex(quranColor);
  }

  Color get footnoteColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF616161);
      case ReaderThemeMode.night:
        return const Color(0xFF9E9E9E);
      case ReaderThemeMode.sepia:
        return const Color(0xFF725B46);
      case ReaderThemeMode.softGray:
        return const Color(0xFF5A6064);
    }
  }

  String get footnoteColorHex {
    return _toHex(footnoteColor);
  }

  Color get hrColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFFE2E4E6);
      case ReaderThemeMode.night:
        return const Color(0xFF273330);
      case ReaderThemeMode.sepia:
        return const Color(0xFFDCCBB5);
      case ReaderThemeMode.softGray:
        return const Color(0xFFC5C9CE);
    }
  }

  String get hrColorHex {
    return _toHex(hrColor);
  }

  /// The primary thematic action/selection color for the active reading theme
  Color get primaryButtonColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return const Color(0xFF0E382F); // Deep Islamic emerald
      case ReaderThemeMode.sepia:
        return const Color(0xFF7A512A); // Warm classic leather brown
      case ReaderThemeMode.night:
        return const Color(0xFF285448); // Deep forest slate-emerald
      case ReaderThemeMode.softGray:
        return const Color(0xFF3F5460); // Refined slate blue-gray
    }
  }

  /// High-contrast foreground/text color on top of [primaryButtonColor]
  Color get primaryButtonTextColor {
    switch (themeMode) {
      case ReaderThemeMode.day:
        return Colors.white;
      case ReaderThemeMode.sepia:
        return const Color(0xFFFFF9ED);
      case ReaderThemeMode.night:
        return const Color(0xFFE9F3EE);
      case ReaderThemeMode.softGray:
        return Colors.white;
    }
  }

  static String _toHex(Color c) {
    return '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  ReaderSettingsState copyWith({
    ReaderThemeMode? themeMode,
    ReaderViewMode? viewMode,
    ReaderFontFamily? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? keepScreenAwake,
  }) {
    return ReaderSettingsState(
      themeMode: themeMode ?? this.themeMode,
      viewMode: viewMode ?? this.viewMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }
}

class ReaderSettingsNotifier extends StateNotifier<ReaderSettingsState> {
  ReaderSettingsNotifier() : super(const ReaderSettingsState()) {
    _loadSettings();
  }

  static const _themeKey = 'reader_theme_mode';
  static const _viewModeKey = 'reader_view_mode';
  static const _fontFamilyKey = 'reader_font_family';
  static const _fontSizeKey = 'reader_font_size';
  static const _lineHeightKey = 'reader_line_height';
  static const _keepAwakeKey = 'reader_keep_awake';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ReaderThemeMode.sepia.index;
    final viewModeIndex = prefs.getInt(_viewModeKey) ?? ReaderViewMode.verticalScroll.index;
    final fontIndex = prefs.getInt(_fontFamilyKey) ?? ReaderFontFamily.amiri.index;
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 18.0;
    final lineHeight = prefs.getDouble(_lineHeightKey) ?? 1.9;
    final keepAwake = prefs.getBool(_keepAwakeKey) ?? false;

    if (keepAwake) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }

    state = ReaderSettingsState(
      themeMode: ReaderThemeMode.values[themeIndex.clamp(0, ReaderThemeMode.values.length - 1)],
      viewMode: ReaderViewMode.values[viewModeIndex.clamp(0, ReaderViewMode.values.length - 1)],
      fontFamily: ReaderFontFamily.values[fontIndex.clamp(0, ReaderFontFamily.values.length - 1)],
      fontSize: fontSize.clamp(14.0, 32.0),
      lineHeight: lineHeight.clamp(1.5, 2.8),
      keepScreenAwake: keepAwake,
    );
  }

  Future<void> setThemeMode(ReaderThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setViewMode(ReaderViewMode mode) async {
    state = state.copyWith(viewMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_viewModeKey, mode.index);
  }

  Future<void> setFontFamily(ReaderFontFamily font) async {
    state = state.copyWith(fontFamily: font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyKey, font.index);
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<void> setLineHeight(double height) async {
    state = state.copyWith(lineHeight: height);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineHeightKey, height);
  }

  Future<void> setKeepScreenAwake(bool awake) async {
    state = state.copyWith(keepScreenAwake: awake);
    try {
      if (awake) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAwakeKey, awake);
  }
}

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettingsState>((ref) {
  return ReaderSettingsNotifier();
});
