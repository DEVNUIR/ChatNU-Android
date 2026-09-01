import 'package:flutter/animation.dart';

/// Centralized spacing tokens for ChatNU.
///
/// Keep feature UI on this scale so compact phone layouts and wide desktop
/// layouts stay visually related without scattering magic numbers.
abstract final class ChatNuSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double ml = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
}

abstract final class ChatNuRadii {
  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
}

/// Blur is intentionally reserved for chrome, overlays and the composer.
/// Scrolling rows and message bubbles should normally use translucency only.
abstract final class ChatNuBlur {
  static const double weak = 8;
  static const double medium = 16;
  static const double strong = 24;
}

abstract final class ChatNuMotion {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration component = Duration(milliseconds: 260);
  static const Duration route = Duration(milliseconds: 380);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve exit = Curves.easeInCubic;
}

abstract final class ChatNuElevation {
  static const double floating = 16;
  static const double overlay = 28;
}

abstract final class ChatNuSizing {
  static const double minTouchTarget = 48;
  static const double compactAvatar = 38;
  static const double avatar = 48;
  static const double largeAvatar = 76;
  static const double navigationRail = 92;
  static const double conversationListTablet = 332;
  static const double conversationListDesktop = 392;
  static const double messageMaxWidth = 620;
  static const double contentMaxWidth = 860;
}
