import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatNuPalette extends ThemeExtension<ChatNuPalette> {
  const ChatNuPalette({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
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
    required this.success,
    required this.warning,
    required this.destructive,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
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
  final Color success;
  final Color warning;
  final Color destructive;

  static const dark = ChatNuPalette(
    backgroundPrimary: Color(0xFF090C12),
    backgroundSecondary: Color(0xFF10151E),
    glassWeak: Color(0x541A2230),
    glassMedium: Color(0x85171E29),
    glassStrong: Color(0xC4141A23),
    borderSubtle: Color(0x24FFFFFF),
    borderHighlight: Color(0x52FFFFFF),
    textPrimary: Color(0xFFF5F7FB),
    textSecondary: Color(0xFFC4CBD8),
    textMuted: Color(0xFF7F899A),
    accentPrimary: Color(0xFF6975FF),
    accentSecondary: Color(0xFF8A6DF2),
    success: Color(0xFF45B984),
    warning: Color(0xFFE9A64C),
    destructive: Color(0xFFE86673),
  );

  static const light = ChatNuPalette(
    backgroundPrimary: Color(0xFFF5F6F8),
    backgroundSecondary: Color(0xFFFFFFFF),
    glassWeak: Color(0xA8FFFFFF),
    glassMedium: Color(0xD9FFFFFF),
    glassStrong: Color(0xF2FFFFFF),
    borderSubtle: Color(0x1F1B2230),
    borderHighlight: Color(0x33FFFFFF),
    textPrimary: Color(0xFF151821),
    textSecondary: Color(0xFF4C5565),
    textMuted: Color(0xFF7C8492),
    accentPrimary: Color(0xFF5361E8),
    accentSecondary: Color(0xFF7659D4),
    success: Color(0xFF218A5E),
    warning: Color(0xFFB8761D),
    destructive: Color(0xFFC74353),
  );

  @override
  ChatNuPalette copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
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
    Color? success,
    Color? warning,
    Color? destructive,
  }) {
    return ChatNuPalette(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
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
      backgroundSecondary: blend(backgroundSecondary, other.backgroundSecondary),
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
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accentPrimary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: palette.backgroundPrimary,
      extensions: <ThemeExtension<dynamic>>[palette],
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: palette.textPrimary,
          height: 1.55,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
          height: 1.5,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: palette.textMuted,
          height: 1.4,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: palette.borderSubtle,
    );
  }
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
