import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF001831);
  static const Color primaryContainer = Color(0xFF002D54);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7495C2);
  static const Color primaryFixed = Color(0xFFD3E4FF);
  static const Color primaryFixedDim = Color(0xFFA7C9F8);
  static const Color onPrimaryFixed = Color(0xFF001D36);
  static const Color inversePrimary = Color(0xFFA7C9F8);

  // Secondary
  static const Color secondary = Color(0xFF505F76);
  static const Color secondaryContainer = Color(0xFFD0E1FB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF54647A);
  static const Color secondaryFixed = Color(0xFFD3E4FE);
  static const Color secondaryFixedDim = Color(0xFFB7C8E1);
  static const Color onSecondaryFixed = Color(0xFF0B1C30);
  static const Color onSecondaryFixedVariant = Color(0xFF38485D);

  // Tertiary
  static const Color tertiary = Color(0xFF2D0F00);
  static const Color tertiaryContainer = Color(0xFF4C1F02);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFC8835D);
  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color tertiaryFixedDim = Color(0xFFFFB68F);
  static const Color onTertiaryFixed = Color(0xFF331200);
  static const Color onTertiaryFixedVariant = Color(0xFF6D3919);

  // Surface
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);

  // On Surface
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color background = Color(0xFFF7F9FB);

  // Inverse
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color surfaceTint = Color(0xFF3F608A);

  // Outline
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC3C6CF);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Extra
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: GoogleFonts.hankenGroteskTextTheme(),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondary,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.onPrimaryContainer,
        onPrimary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryFixed,
        secondary: AppColors.secondaryContainer,
        surface: Color(0xFF121820),
        onSurface: Color(0xFFE8ECF0),
        onSurfaceVariant: Color(0xFFB0B8C4),
        outline: AppColors.outline,
        outlineVariant: Color(0xFF3A4450),
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.hankenGroteskTextTheme(
        ThemeData.dark().textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFF121820),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121820),
        elevation: 0,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryFixed,
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryFixed),
      ),
    );
  }
}

// Text Styles
class AppTextStyles {
  static TextStyle headlineLg(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        color: AppColors.onSurface,
      );

  static TextStyle headlineLgMobile(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 26,
        color: AppColors.onSurface,
      );

  static TextStyle headlineMd(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle headlineSm(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle bodyLg(BuildContext context) => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle bodyMd(BuildContext context) => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle bodySm(BuildContext context) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle labelMd(BuildContext context) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        color: AppColors.onSurface,
      );

  static TextStyle labelSm(BuildContext context) => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 12,
        color: AppColors.onSurface,
      );
}
