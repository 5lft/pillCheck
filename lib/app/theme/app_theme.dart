import 'package:material_ui/material_ui.dart';

/// 앱 전용 색. ColorScheme 슬롯으로 표현하기 애매한 값들을 모아 둔다.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.danger,
    required this.dangerSoft,
    required this.fill,
  });

  final Color background;
  final Color card;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color danger;
  final Color dangerSoft;

  /// 입력창·칩 같은 옅은 채움 색
  final Color fill;

  static const light = AppPalette(
    background: Color(0xFFF2F4F6),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE5E8EB),
    accent: Color(0xFF3D6BFF),
    accentSoft: Color(0xFFEBF0FF),
    textPrimary: Color(0xFF191F28),
    textSecondary: Color(0xFF6B7684),
    textTertiary: Color(0xFFB0B8C1),
    danger: Color(0xFFF04452),
    dangerSoft: Color(0xFFFFEEEF),
    fill: Color(0xFFF2F4F6),
  );

  static const dark = AppPalette(
    background: Color(0xFF101013),
    card: Color(0xFF1C1C21),
    border: Color(0xFF2C2C34),
    accent: Color(0xFF5B83FF),
    accentSoft: Color(0xFF1F2A4A),
    textPrimary: Color(0xFFF2F4F6),
    textSecondary: Color(0xFF9EA6B0),
    textTertiary: Color(0xFF5C636C),
    danger: Color(0xFFFF5A66),
    dangerSoft: Color(0xFF3A1E22),
    fill: Color(0xFF26262D),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      card: l(card, other.card),
      border: l(border, other.border),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      fill: l(fill, other.fill),
    );
  }
}

abstract final class AppTheme {
  static const radius = 20.0;

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: Colors.white,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.accent,
      secondary: p.accent,
      onSecondary: Colors.white,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.accent,
      error: p.danger,
      onError: Colors.white,
      surface: p.card,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.textTertiary,
      outlineVariant: p.border,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: p.card,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest: p.fill,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(brightness: brightness, colorScheme: scheme);
    final text = base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );
    final textTheme = text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.25,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, letterSpacing: -0.1),
      bodySmall: text.bodySmall?.copyWith(
        fontSize: 13,
        color: p.textSecondary,
        letterSpacing: -0.1,
      ),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: [p],
      appBarTheme: AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textTertiary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textTertiary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: p.fill,
        hintStyle: TextStyle(color: p.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: rounded,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: p.textSecondary,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF333D4B)
            : const Color(0xFF3A3A44),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: rounded,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    );
  }
}
