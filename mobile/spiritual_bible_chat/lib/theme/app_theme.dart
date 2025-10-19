import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color obsidian = Color(0xFF0B0B0F);
  static const Color onyx = Color(0xFF121218);
  static const Color dune = Color(0xFF2A2721);
  static const Color papyrus = Color(0xFFF2EEE6);
  static const Color quartz = Color(0xFFC8C6C2);
  static const Color aetherBlue = Color(0xFF69C6D0);
  static const Color maatGold = Color(0xFFC6A664);
  static const Color lotusRose = Color(0xFFF0A7A7);
  static const Color scarabGreen = Color(0xFF4AB58A);
  static const Color desertSun = Color(0xFFFFB757);
}

class AppGradients {
  static const LinearGradient dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.obsidian,
      AppColors.onyx,
      AppColors.dune,
    ],
  );

  static const LinearGradient aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5BD6E0),
      AppColors.aetherBlue,
      AppColors.maatGold,
    ],
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final interText = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.papyrus,
    displayColor: AppColors.papyrus,
  );

  TextStyle cinzel(TextStyle? original) => GoogleFonts.cinzel(
        textStyle: original,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
      );

  final textTheme = interText.copyWith(
    displayLarge: cinzel(interText.displayLarge),
    displayMedium: cinzel(interText.displayMedium),
    displaySmall: cinzel(interText.displaySmall),
    headlineLarge: cinzel(interText.headlineLarge),
    headlineMedium: cinzel(interText.headlineMedium),
    headlineSmall: cinzel(interText.headlineSmall),
    titleLarge: GoogleFonts.inter(
      textStyle: interText.titleLarge,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      textStyle: interText.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      textStyle: interText.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.inter(
      textStyle: interText.bodyLarge,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: GoogleFonts.inter(
      textStyle: interText.bodyMedium,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: GoogleFonts.inter(
      textStyle: interText.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.01,
    ),
  );

  final colorScheme = ColorScheme.dark(
    primary: AppColors.maatGold,
    onPrimary: AppColors.obsidian,
    secondary: AppColors.aetherBlue,
    onSecondary: AppColors.obsidian,
    surface: AppColors.onyx.withOpacity(0.9),
    onSurface: AppColors.papyrus,
    error: AppColors.lotusRose,
    onError: AppColors.obsidian,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: colorScheme,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle:
          textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: AppColors.maatGold),
    ),
    cardTheme: CardTheme(
      color: AppColors.onyx.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.maatGold,
        foregroundColor: AppColors.obsidian,
        textStyle: textTheme.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: AppColors.maatGold),
        foregroundColor: AppColors.maatGold,
        textStyle: textTheme.titleMedium,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.onyx.withOpacity(0.55),
      selectedColor: AppColors.aetherBlue.withOpacity(0.3),
      labelStyle: textTheme.bodyMedium!,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.dune),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.dune.withOpacity(0.92),
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.zero,
      iconColor: AppColors.maatGold,
      textColor: AppColors.papyrus,
      subtitleTextStyle:
          textTheme.bodyMedium?.copyWith(color: AppColors.quartz),
    ),
  );
}
