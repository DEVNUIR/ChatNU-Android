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
    backgroundPrimary: Color(0xFF080D16),
    backgroundSecondary: Color(0xFF0D1420),
    backgroundElevated: Color(0xFF121B29),
    glassWeak: Color(0x70131C2B),
    glassMedium: Color(0xA8172232),
    glassStrong: Color(0xD4182230),
    borderSubtle: Color(0x24FFFFFF),
    borderHighlight: Color(0x42FFFFFF),
    textPrimary: Color(0xFFF6F8FC),
    textSecondary: Color(0xFFC5CCDA),
    textMuted: Color(0xFF8994A7),
    accentPrimary: Color(0xFF5B7CFF),
    accentSecondary: Color(0xFF826BFF),
    accentCyan: Color(0xFF59C8E8),
    success: Color(0xFF48BE8A),
    warning: Color(0xFFF0A84D),
    destructive: Color(0xFFEF6876),
  );

  static const light = ChatNuPalette(
    backgroundPrimary: Color(0xFFF3F6FB),
    backgroundSecondary: Color(0xFFF9FBFE),
    backgroundElevated: Color(0xFFFFFFFF),
    glassWeak: Color(0xB8FFFFFF),
    glassMedium: Color(0xD9FFFFFF),
    glassStrong: Color(0xF2FFFFFF),
    borderSubtle: Color(0x171C2B44),
    borderHighlight: Color(0x7AFFFFFF),
    textPrimary: Color(0xFF121826),
    textSecondary: Color(0xFF4B586D),
    textMuted: Color(0xFF7D899B),
    accentPrimary: Color(0xFF526FEA),
    accentSecondary: Color(0xFF7259DD),
    accentCyan: Color(0xFF268FAA),
    success: Color(0xFF20845D),
    warning: Color(0xFFB66B13),
    destructive: Color(0xFFC94353),
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.accentPrimary,
      brightness: brightness,
      surface: palette.backgroundElevated,
      error: palette.destructive,
    ).copyWith(
      primary: palette.accentPrimary,
      secondary: palette.accentSecondary,
      tertiary: palette.accentCyan,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.borderSubtle,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.backgroundPrimary,
      extensions: <ThemeExtension<dynamic>>[palette],
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.45,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: palette.textPrimary,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: palette.textSecondary,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: palette.textMuted,
        height: 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: palette.borderSubtle),
    );
    return base.copyWith(
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: palette.borderSubtle,
      dividerTheme: DividerThemeData(color: palette.borderSubtle, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glassWeak,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: palette.accentPrimary.withValues(alpha: 0.72),
            width: 1.4,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.backgroundElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.borderSubtle),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.backgroundElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      focusColor: palette.accentPrimary.withValues(alpha: 0.14),
    );
  }
}
