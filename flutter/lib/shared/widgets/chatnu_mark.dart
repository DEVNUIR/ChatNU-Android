import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/material.dart';

class ChatNuMark extends StatelessWidget {
  const ChatNuMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[palette.accentPrimary, palette.accentSecondary],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.accentPrimary.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.auto_awesome_rounded, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}
