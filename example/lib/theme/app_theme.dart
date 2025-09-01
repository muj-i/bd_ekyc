import 'package:example/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData appLightTheme = ThemeData(
    useMaterial3: false,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      surfaceTintColor: AppColors.white,
      elevation: 0,
    ),
    scaffoldBackgroundColor: AppColors.white,
    primarySwatch: MaterialColor(
      AppColors.primary.toARGB32(),
      AppColors.colorPaletteColors,
    ),
    popupMenuTheme: const PopupMenuThemeData(color: AppColors.white),
    drawerTheme: const DrawerThemeData(
      elevation: 0,
      backgroundColor: AppColors.white,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.white),
    primaryTextTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      displaySmall: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: TextStyle(color: AppColors.black, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(color: AppColors.black, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      labelMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
      headlineSmall: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w400,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(AppColors.primary),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.black),
      displayMedium: TextStyle(color: AppColors.black),
      displaySmall: TextStyle(color: AppColors.black),
      titleLarge: TextStyle(color: AppColors.black),
      titleMedium: TextStyle(color: AppColors.black),
      titleSmall: TextStyle(color: AppColors.black),
      bodyLarge: TextStyle(color: AppColors.black),
      bodyMedium: TextStyle(color: AppColors.black),
      bodySmall: TextStyle(color: AppColors.black),
      labelLarge: TextStyle(color: AppColors.black),
      labelMedium: TextStyle(color: AppColors.black),
      labelSmall: TextStyle(color: AppColors.black),
      headlineLarge: TextStyle(color: AppColors.black),
      headlineMedium: TextStyle(color: AppColors.black),
      headlineSmall: TextStyle(color: AppColors.black),
    ),
    //* text field theme
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      labelStyle: TextStyle(color: AppColors.black.withValues(alpha: .80)),
      hintStyle: TextStyle(color: AppColors.black.withValues(alpha: .45)),
      filled: true,
      fillColor: AppColors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: .3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: BorderSide(color: AppColors.black.withValues(alpha: .3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      errorStyle: const TextStyle(color: AppColors.red),
    ),
    //* elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all<Size>(const Size.fromHeight(40.0)),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.white,
        ),
        shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
          (states) =>
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
        ),
        textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) =>
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    //* Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.black,
        ),
        side: WidgetStateProperty.resolveWith<BorderSide?>(
          (states) => const BorderSide(color: AppColors.black),
        ),
        shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
          (states) =>
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        ),
        textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) =>
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),
    //* Switch theme
    switchTheme: SwitchThemeData(
      overlayColor: WidgetStateProperty.all<Color>(AppColors.transparent),
      thumbColor: WidgetStateProperty.all<Color>(AppColors.white),
    ),
    iconTheme: const IconThemeData(color: AppColors.primary),
  );
}
