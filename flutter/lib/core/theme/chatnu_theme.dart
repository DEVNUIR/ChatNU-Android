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
    backgroundPrimary: Color(0xFF101010),
    backgroundSecondary: Color(0xFF151515),
    backgroundElevated: Color(0xFF1A1A1A),
    glassWeak: Color(0xFF202020),
    glassMedium: Color(0xFF252525),
    glassStrong: Color(0xFF1A1A1A),
    borderSubtle: Color(0xFF2B2B2B),
    borderHighlight: Color(0xFF3B3B3B),
    textPrimary: Color(0xFFF7F7F7),
    textSecondary: Color(0xFFC7C7C7),
    textMuted: Color(0xFF878787),
    accentPrimary: Color(0xFFFFCC00),
    accentSecondary: Color(0xFFF7F7F7),
    accentCyan: Color(0xFF64B5F6),
    success: Color(0xFF4FCF88),
    warning: Color(0xFFFFCC00),
    destructive: Color(0xFFFF5A5F),
  );

  static const light = ChatNuPalette(
    backgroundPrimary: Color(0xFFF3F3F3),
    backgroundSecondary: Color(0xFFFFFFFF),
    backgroundElevated: Color(0xFFFFFFFF),
    glassWeak: Color(0xFFF7F7F7),
    glassMedium: Color(0xFFF2F2F2),
    glassStrong: Color(0xFFFFFFFF),
    borderSubtle: Color(0xFFECECEC),
    borderHighlight: Color(0xFFDADADA),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF545454),
    textMuted: Color(0xFF8A8A8A),
    accentPrimary: Color(0xFFFFCC00),
    accentSecondary: Color(0xFF111111),
    accentCyan: Color(0xFF1473E6),
    success: Color(0xFF168A54),
    warning: Color(0xFFB88600),
    destructive: Color(0xFFD83A42),
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
          onPrimary: const Color(0xFF111111),
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
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.55,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: palette.textPrimary,
        height: 1.42,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: palette.textSecondary,
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: palette.textMuted,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: palette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: palette.borderSubtle),
    );
    return base.copyWith(
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
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
