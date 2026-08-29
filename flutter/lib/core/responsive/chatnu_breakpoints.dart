import 'package:flutter/widgets.dart';

enum ChatNuWindowClass { phone, tablet, desktop }

abstract final class ChatNuBreakpoints {
  static const double tablet = 720;
  static const double desktop = 1180;
  static const double conversationMaxWidth = 920;

  static ChatNuWindowClass fromWidth(double width) {
    if (width >= desktop) return ChatNuWindowClass.desktop;
    if (width >= tablet) return ChatNuWindowClass.tablet;
    return ChatNuWindowClass.phone;
  }

  static ChatNuWindowClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }
}
