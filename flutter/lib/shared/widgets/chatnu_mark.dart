import 'package:flutter/material.dart';

class ChatNuMark extends StatelessWidget {
  const ChatNuMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'ChatNU',
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.27),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1769E8).withValues(alpha: 0.24),
                blurRadius: size * 0.36,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: Image.asset(
            'assets/brand/chatnu_launcher.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
