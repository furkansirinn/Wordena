import 'package:flutter/material.dart';

class AppColors {
  // Pastel Mavi (Ana renk) - Soft sky blue
  static const Color primary = Color(0xFFADD8E6);

  // Pastel Turkuaz (Vurgu) - Fresh aqua
  static const Color accent = Color(0xFF7FFFD4);

  // Koyu Gri (Metin)
  static const Color text = Color(0xFF4A4A4A);

  // Soft Cream (Arkaplan) - Warm, inviting
  static const Color background = Color(0xFFFFFAF0);

  // Pastel Pembe
  static const Color pastelPink = Color(0xFFFFB3D9);

  // Pastel Yeşil
  static const Color pastelGreen = Color(0xFFC1FFA9);

  // Pastel Turuncu
  static const Color pastelOrange = Color(0xFFFFDDB3);

  // Pastel Peach (Yeni - şeker tonlu)
  static const Color pastelPeach = Color(0xFFFFD1A3);

  // Pastel Mint (Yeni - ferah)
  static const Color pastelMint = Color(0xFFB3F5E6);

  // Pastel Lavender (Yeni - yumuşak)
  static const Color pastelLavender = Color(0xFFE6D9F5);
}

class AppTheme {
  // Pastel Açık Tema (tek tema)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColors.text,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text.withOpacity(0.4),
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),

    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: AppColors.text,
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),

    cardTheme: const CardThemeData(
      color: AppColors.background,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(AppColors.primary),
        foregroundColor: MaterialStateProperty.all(AppColors.text),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );

  // Dark mode kaldırıldı - sadece açık tema var
  static ThemeData get darkTheme => lightTheme;
}