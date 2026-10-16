import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final textTheme = Typography.material2021().black.copyWith(
      displaySmall: const TextStyle(
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
      ),
      headlineSmall: const TextStyle(
        fontSize: 21,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: const TextStyle(fontSize: 15, height: 1.4, letterSpacing: 0),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.4, letterSpacing: 0),
      bodySmall: const TextStyle(fontSize: 12, height: 1.35, letterSpacing: 0),
      labelLarge: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand800,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.brand800,
          onPrimary: Colors.white,
          primaryContainer: AppColors.brand50,
          onPrimaryContainer: AppColors.brand900,
          secondary: AppColors.brand600,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.brand100,
          onSecondaryContainer: AppColors.brand900,
          tertiary: AppColors.accent500,
          onTertiary: Colors.white,
          tertiaryContainer: AppColors.accent100,
          onTertiaryContainer: AppColors.accent700,
          error: AppColors.danger600,
          surface: AppColors.glassStrong,
          onSurface: AppColors.ink,
          surfaceContainerHighest: AppColors.surfaceMuted,
          outline: AppColors.line,
        );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.line),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.brandSoft,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.brandSoft,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        color: AppColors.glassStrong,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassStrong,
        selectedColor: AppColors.brand100,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(
          color: AppColors.brand900,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent100,
          disabledForegroundColor: AppColors.accent700,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand800,
          side: const BorderSide(color: AppColors.brand200),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.brand100,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand800
                : AppColors.zinc500,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand800
                : AppColors.zinc500,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassStrong,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.brand700, width: 1.6),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger600, width: 1.3),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger600, width: 1.6),
        ),
        prefixIconColor: AppColors.zinc500,
        suffixIconColor: AppColors.zinc500,
        labelStyle: const TextStyle(color: AppColors.zinc700),
        helperStyle: const TextStyle(color: AppColors.zinc500),
      ),
      listTileTheme: const ListTileThemeData(
        dense: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        minLeadingWidth: 38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.zinc950,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.zinc500,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 20,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand700,
        linearTrackColor: AppColors.brand100,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.brand950,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
