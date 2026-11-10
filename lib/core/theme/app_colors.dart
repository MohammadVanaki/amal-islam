import 'package:flutter/material.dart';

class AppColors {
  // --- پالت رنگ فاخر اسلامی (Islamic Emerald & Royal Gold) ---
  static const Color primary = Color(0xFF0E382F); // یشمی اصیل و عمیق
  static const Color primaryLight = Color(
    0xFF1E5246,
  ); // سبز یشمی روشن‌تر برای المان‌ها
  static const Color primaryDark = Color(
    0xFF08221C,
  ); // یشمی تیره برای گرادینت‌ها
  static const Color primaryContainer = Color(0xFFE8F2EF); // زمینه محو یشمی

  static const Color accent = Color(0xFFC59B27); // طلایی اشرافی و درخشان
  static const Color accentLight = Color(0xFFE5BE53); // طلایی روشن
  static const Color accentContainer = Color(0xFFFFF7DC); // زمینه طلایی ملایم

  // گرادینت‌های لوکس
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1E5246), Color(0xFF0E382F)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFE5BE53), Color(0xFFC59B27)],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0E382F)],
  );

  // --- پس‌زمینه‌ها و سطوح ---
  static const Color backgroundLight = Color(
    0xFFF7F8F7,
  ); // عاجی بسیار ملایم شبیه کاغذ اعلا
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE8ECE8);

  static const Color backgroundDark = Color(0xFF0A1311); // شب زمردی تیره
  static const Color surfaceDark = Color(0xFF14211E);
  static const Color cardDark = Color(0xFF192A26);
  static const Color borderDark = Color(0xFF233833);

  // --- حالت‌های ویژه مطالعه کتاب (Reading Modes) ---
  static const Color sepiaBackground = Color(0xFFFBF4E6); // کاغذ کهن سپیا
  static const Color sepiaText = Color(0xFF483623); // جوهر قهوه‌ای کهن

  static const Color dayBackground = Colors.white;
  static const Color dayText = Color(0xFF1F2422);

  static const Color nightBackground = Color(0xFF0F1514);
  static const Color nightText = Color(0xFFE1E7E5);

  static const Color softGrayBackground = Color(0xFFE8EAEB);
  static const Color softGrayText = Color(0xFF22272A);

  // --- رنگ‌های هایلایت متن ---
  static const Color highlightYellow = Color(0x66FFEB3B);
  static const Color highlightGreen = Color(0x664CAF50);
  static const Color highlightBlue = Color(0x662196F3);
  static const Color highlightPink = Color(0x66E91E63);

  // --- وضعیت‌ها ---
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color downloadProgress = Color(0xFF0288D1);

  // --- متن‌ها ---
  static const Color textPrimaryLight = Color(0xFF17201D);
  static const Color textSecondaryLight = Color(0xFF677570);
  static const Color textPrimaryDark = Color(0xFFF1F5F3);
  static const Color textSecondaryDark = Color(0xFF9BA9A4);
}
