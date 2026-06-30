import 'package:flutter/material.dart';

/// ====================================================
/// アプリカラーパレット（ダークネイビーテーマ）
/// ====================================================
class AppColors {
  AppColors._();

  // --- 背景 ---
  static const Color background = Color(0xFF0F1729);
  static const Color surface = Color(0xFF1A2540);
  static const Color surfaceLight = Color(0xFF1E2D4E);
  static const Color cardBg = Color(0xFF162036);

  // --- テキスト ---
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8A9BBF);
  static const Color textMuted = Color(0xFF4A5A7A);

  // --- アクセント ---
  static const Color teal = Color(0xFF00D4FF);
  static const Color tealDark = Color(0xFF0099BB);
  static const Color tealGlow = Color(0x3300D4FF);

  // --- ステータスカラー ---
  static const Color positive = Color(0xFF4ADE80);  // プラス・良好（エメラルド）
  static const Color negative = Color(0xFFFF6B6B);  // マイナス・警告（コーラル）
  static const Color warning = Color(0xFFF59E0B);   // 注意（アンバー）
  static const Color purple = Color(0xFFA855F7);    // サブアクセント（パープル）

  // --- ボーダー ---
  static const Color border = Color(0xFF2A3A5E);
  static const Color borderLight = Color(0xFF3A4A6E);

  // --- チャートカラー（銘柄ごとのユニーク色） ---
  static const List<Color> chartColors = [
    Color(0xFF00D4FF), // ティール
    Color(0xFFFF6B6B), // コーラル
    Color(0xFFF59E0B), // アンバー
    Color(0xFF4ADE80), // エメラルド
    Color(0xFFA855F7), // パープル
    Color(0xFFEC4899), // ピンク
    Color(0xFF3B82F6), // ブルー
    Color(0xFF14B8A6), // ティールグリーン
    Color(0xFFF97316), // オレンジ
    Color(0xFF84CC16), // ライムグリーン
    Color(0xFF6366F1), // インディゴ
    Color(0xFFEF4444), // レッド
  ];
}

/// ====================================================
/// アプリテーマ定義
/// ====================================================
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        secondary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.negative,
        onPrimary: AppColors.background,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),

      cardTheme: CardTheme(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
