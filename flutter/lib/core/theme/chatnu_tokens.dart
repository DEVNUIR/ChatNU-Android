import 'package:flutter/animation.dart';

abstract final class ChatNuSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class ChatNuRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
}

abstract final class ChatNuBlur {
  static const double weak = 6;
  static const double medium = 12;
  static const double strong = 18;
}

abstract final class ChatNuMotion {
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration component = Duration(milliseconds: 220);
  static const Duration route = Duration(milliseconds: 280);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);
}

abstract final class ChatNuElevation {
  static const double floating = 16;
  static const double overlay = 28;
}
