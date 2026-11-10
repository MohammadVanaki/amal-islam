import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'app_theme_mode';
const String _kAppPaletteKey = 'app_palette_key';

enum AppPalette {
  emerald(
    id: 'emerald',
    name: 'الأخضر الزمردي',
    color: Color(0xFF176E54),
    primaryLight: Color(0xFF23896A),
    accent: Color(0xFFC59B27),
  ),
  cyan(
    id: 'cyan',
    name: 'الأزرق الفيروزي',
    color: Color(0xFF53C0E8),
    primaryLight: Color(0xFF0B829E),
    accent: Color(0xFFFFB300),
  ),
  bronze(
    id: 'bronze',
    name: 'البرونزي الأصيل',
    color: Color(0xFF916839),
    primaryLight: Color(0xFFB0824E),
    accent: Color(0xFFD4AF37),
  ),
  slate(
    id: 'slate',
    name: 'الرمادي المزرق',
    color: Color(0xFF5B6984),
    primaryLight: Color(0xFF7686A3),
    accent: Color(0xFF00B0FF),
  ),
  navy(
    id: 'navy',
    name: 'الأزرق الملكي',
    color: Color(0xFF114E80),
    primaryLight: Color(0xFF1E6CA8),
    accent: Color(0xFFFFC107),
  );

  final String id;
  final String name;
  final Color color;
  final Color primaryLight;
  final Color accent;

  const AppPalette({
    required this.id,
    required this.name,
    required this.color,
    required this.primaryLight,
    required this.accent,
  });

  static AppPalette fromId(String? id) {
    return AppPalette.values.firstWhere(
      (p) => p.id == id,
      orElse: () => AppPalette.bronze,
    );
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_kThemeModeKey);
    if (savedMode == 'light') {
      state = ThemeMode.light;
    } else if (savedMode == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_kThemeModeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_kThemeModeKey, 'dark');
    } else {
      await prefs.setString(_kThemeModeKey, 'system');
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class AppPaletteNotifier extends StateNotifier<AppPalette> {
  AppPaletteNotifier() : super(AppPalette.bronze) {
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPalette = prefs.getString(_kAppPaletteKey);
    state = AppPalette.fromId(savedPalette);
  }

  Future<void> setPalette(AppPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppPaletteKey, palette.id);
  }
}

final appPaletteProvider = StateNotifierProvider<AppPaletteNotifier, AppPalette>((ref) {
  return AppPaletteNotifier();
});
