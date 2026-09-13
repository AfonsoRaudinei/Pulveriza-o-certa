import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0057FF);
  static const primaryDark = Color(0xFF0041CC);
  static const primaryLight = Color(0xFFEBF2FF);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const cardSurface = Color(0xF2FFFFFF);
  static const surfaceAlt = Color(0xFFF9FAFB);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const borderFocus = Color(0xFF0057FF);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const purple = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFEDE9FE);
  static const orange = Color(0xFFEA580C);
  static const orangeBackground = Color(0xFFFFF7ED);
  static const orangeBorder = Color(0xFFFDBA74);
  static const orangeIconBackground = Color(0xFFFFEDD5);
  static const orangeText = Color(0xFFC2410C);

  static const darkBackground = Color(0xFF0F1218);
  static const darkSurface = Color(0xFF1A1F27);
  static const darkCardSurface = Color(0xF21A1F27);
  static const darkSurfaceAlt = Color(0xFF222830);
  static const darkTextPrimary = Color(0xFFF3F4F6);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkTextTertiary = Color(0xFF6B7280);
  static const darkBorder = Color(0xFF2D3340);
  static const darkPrimaryLight = Color(0xFF15233F);
  static const darkSuccessLight = Color(0xFF06281E);
  static const darkWarningLight = Color(0xFF2A1C06);
  static const darkDangerLight = Color(0xFF2A0F0F);
  static const darkSuccess = Color(0xFF34D399);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkDanger = Color(0xFFF87171);
  static const darkInfo = Color(0xFF60A5FA);
  static const darkOrange = Color(0xFFFB923C);
  static const darkOrangeBackground = Color(0xFF2A1508);
  static const darkOrangeBorder = Color(0xFF9A3412);
  static const darkOrangeIconBackground = Color(0xFF3D1F0A);
  static const darkOrangeText = Color(0xFFFDBA74);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;
}

class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const full = 999.0;
}

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.primaryLight,
    required this.successLight,
    required this.warningLight,
    required this.dangerLight,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.primary,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color primaryLight;
  final Color successLight;
  final Color warningLight;
  final Color dangerLight;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color primary;

  static const light = AppThemeColors(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: AppColors.border,
    primaryLight: AppColors.primaryLight,
    successLight: AppColors.successLight,
    warningLight: AppColors.warningLight,
    dangerLight: AppColors.dangerLight,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    primary: AppColors.primary,
  );

  static const dark = AppThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
    primaryLight: AppColors.darkPrimaryLight,
    successLight: AppColors.darkSuccessLight,
    warningLight: AppColors.darkWarningLight,
    dangerLight: AppColors.darkDangerLight,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    danger: AppColors.darkDanger,
    info: AppColors.darkInfo,
    primary: AppColors.primary,
  );

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.light;
  }

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? primaryLight,
    Color? successLight,
    Color? warningLight,
    Color? dangerLight,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? primary,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      primaryLight: primaryLight ?? this.primaryLight,
      successLight: successLight ?? this.successLight,
      warningLight: warningLight ?? this.warningLight,
      dangerLight: dangerLight ?? this.dangerLight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      primary: primary ?? this.primary,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        colors: AppThemeColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colors: AppThemeColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppThemeColors colors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.danger,
      outline: colors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[colors],
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.border,
      textTheme: base.textTheme.apply(fontFamily: 'Inter').copyWith(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: colors.textPrimary,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: colors.textSecondary,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: colors.textSecondary,
            ),
            labelLarge: const TextStyle(
                fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
            labelMedium: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
            labelSmall: const TextStyle(
                fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderFocus),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? colors.surfaceAlt
            : AppColors.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: brightness == Brightness.dark
              ? colors.textPrimary
              : AppColors.surface,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceAlt,
        selectedColor: colors.primaryLight,
        side: BorderSide(color: colors.border),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
