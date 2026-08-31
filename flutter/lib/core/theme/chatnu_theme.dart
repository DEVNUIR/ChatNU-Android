import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/material.dart';

class ChatNuPalette extends ThemeExtension<ChatNuPalette> {
  const ChatNuPalette({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundElevated,
    required this.glassWeak,
    required this.glassMedium,
    required this.glassStrong,
    required this.borderSubtle,
    required this.borderHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentCyan,
    required this.success,
    required this.warning,
    required this.destructive,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundElevated;
  final Color glassWeak;
  final Color glassMedium;
  final Color glassStrong;
  final Color borderSubtle;
  final Color borderHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentCyan;
  final Color success;
  final Color warning;
  final Color destructive;

  static const dark = ChatNuPalette(
    backgroundPrimary: Color(0xFF060A12),
    backgroundSecondary: Color(0xFF0B111D),
    backgroundElevated: Color(0xFF111A2A),
    glassWeak: Color(0xFF111A28),
    glassMedium: Color(0xFF172338),
    glassStrong: Color(0xFF1C2940),
    borderSubtle: Color(0xFF24324A),
    borderHighlight: Color(0xFF3B4E70),
    textPrimary: Color(0xFFF7FAFF),
    textSecondary: Color(0xFFB9C5D8),
    textMuted: Color(0xFF75839B),
    accentPrimary: Color(0xFF2F7CFF),
    accentSecondary: Color(0xFF8068F2),
    accentCyan: Color(0xFF24D5ED),
    success: Color(0xFF37D38B),
    warning: Color(0xFFF7BF4B),
    destructive: Color(0xFFFF6574),
  );

  static const light = ChatNuPalette(
    backgroundPrimary: Color(0xFFF2F6FC),
    backgroundSecondary: Color(0xFFF8FAFE),
    backgroundElevated: Color(0xFFFFFFFF),
    glassWeak: Color(0xFFF9FBFF),
    glassMedium: Color(0xFFF1F6FD),
    glassStrong: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFDDE6F2),
    borderHighlight: Color(0xFFCBD8E9),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF8190A5),
    accentPrimary: Color(0xFF1769E8),
    accentSecondary: Color(0xFF6C56D9),
    accentCyan: Color(0xFF0EAFC7),
    success: Color(0xFF12835A),
    warning: Color(0xFFA96F05),
    destructive: Color(0xFFD93C50),
  );

  @override
  ChatNuPalette copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundElevated,
    Color? glassWeak,
    Color? glassMedium,
    Color? glassStrong,
    Color? borderSubtle,
    Color? borderHighlight,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentCyan,
    Color? success,
    Color? warning,
    Color? destructive,
  }) {
    return ChatNuPalette(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      glassWeak: glassWeak ?? this.glassWeak,
      glassMedium: glassMedium ?? this.glassMedium,
      glassStrong: glassStrong ?? this.glassStrong,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderHighlight: borderHighlight ?? this.borderHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentCyan: accentCyan ?? this.accentCyan,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      destructive: destructive ?? this.destructive,
    );
  }

  @override
  ChatNuPalette lerp(covariant ChatNuPalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return ChatNuPalette(
      backgroundPrimary: blend(backgroundPrimary, other.backgroundPrimary),
      backgroundSecondary: blend(
        backgroundSecondary,
        other.backgroundSecondary,
      ),
      backgroundElevated: blend(backgroundElevated, other.backgroundElevated),
      glassWeak: blend(glassWeak, other.glassWeak),
      glassMedium: blend(glassMedium, other.glassMedium),
      glassStrong: blend(glassStrong, other.glassStrong),
      borderSubtle: blend(borderSubtle, other.borderSubtle),
      borderHighlight: blend(borderHighlight, other.borderHighlight),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      accentPrimary: blend(accentPrimary, other.accentPrimary),
      accentSecondary: blend(accentSecondary, other.accentSecondary),
      accentCyan: blend(accentCyan, other.accentCyan),
      success: blend(success, other.success),
      warning: blend(warning, other.warning),
      destructive: blend(destructive, other.destructive),
    );
  }
}

extension ChatNuThemeContext on BuildContext {
  ChatNuPalette get chatNu => Theme.of(this).extension<ChatNuPalette>()!;
}

abstract final class ChatNuTheme {
  static ThemeData get dark => _build(Brightness.dark, ChatNuPalette.dark);
  static ThemeData get light => _build(Brightness.light, ChatNuPalette.light);

  static ThemeData _build(Brightness brightness, ChatNuPalette palette) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.accentPrimary,
          brightness: brightness,
          surface: palette.backgroundElevated,
          error: palette.destructive,
        ).copyWith(
          primary: palette.accentPrimary,
          onPrimary: Colors.white,
          secondary: palette.accentSecondary,
          tertiary: palette.accentCyan,
          onSurface: palette.textPrimary,
          onSurfaceVariant: palette.textSecondary,
          outline: palette.borderSubtle,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Manrope',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.backgroundPrimary,
      extensions: <ThemeExtension<dynamic>>[palette],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    final typeBase = base.textTheme.apply(
      fontFamily: 'Manrope',
      fontFamilyFallback: const <String>['NotoSansArabic'],
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );
    final textTheme = typeBase.copyWith(
      displaySmall: typeBase.displaySmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.15,
        height: 1.08,
      ),
      headlineMedium: typeBase.headlineMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.12,
      ),
      headlineSmall: typeBase.headlineSmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.55,
        height: 1.18,
      ),
      titleLarge: typeBase.titleLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.2,
      ),
      titleMedium: typeBase.titleMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: typeBase.bodyLarge?.copyWith(
        color: palette.textPrimary,
        height: 1.5,
      ),
      bodyMedium: typeBase.bodyMedium?.copyWith(
        color: palette.textSecondary,
        height: 1.46,
      ),
      bodySmall: typeBase.bodySmall?.copyWith(
        color: palette.textMuted,
        height: 1.42,
      ),
      labelLarge: typeBase.labelLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: palette.borderSubtle),
    );
    return base.copyWith(
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      hoverColor: palette.textPrimary.withValues(alpha: 0.045),
      highlightColor: palette.textPrimary.withValues(alpha: 0.065),
      focusColor: palette.accentPrimary.withValues(alpha: 0.22),
      dividerColor: palette.borderSubtle,
      dividerTheme: DividerThemeData(color: palette.borderSubtle, space: 1),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(ChatNuSizing.minTouchTarget),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatNuRadii.lg),
          side: BorderSide(color: palette.borderSubtle),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            ChatNuSizing.minTouchTarget,
            ChatNuSizing.minTouchTarget,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            ChatNuSizing.minTouchTarget,
            ChatNuSizing.minTouchTarget,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            ChatNuSizing.minTouchTarget,
            ChatNuSizing.minTouchTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glassWeak,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: palette.textPrimary, width: 1.3),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: brightness == Brightness.light ? Colors.white : Colors.black,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.textPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: brightness == Brightness.light ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
