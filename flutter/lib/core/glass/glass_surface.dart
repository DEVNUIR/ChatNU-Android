import 'dart:ui';

import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GlassVariant { weak, medium, strong }
enum GlassEffectLevel { full, balanced, reduced }

class GlassEffectController extends Notifier<GlassEffectLevel> {
  @override
  GlassEffectLevel build() => GlassEffectLevel.balanced;

  void setLevel(GlassEffectLevel level) => state = level;
}

final NotifierProvider<GlassEffectController, GlassEffectLevel>
glassEffectLevelProvider =
    NotifierProvider<GlassEffectController, GlassEffectLevel>(
      GlassEffectController.new,
    );

class GlassSurface extends ConsumerWidget {
  const GlassSurface({
    required this.child,
    super.key,
    this.variant = GlassVariant.medium,
    this.borderRadius = ChatNuRadii.lg,
    this.padding = EdgeInsets.zero,
    this.enableBlur = false,
  });

  final Widget child;
  final GlassVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool enableBlur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.chatNu;
    final effectLevel = ref.watch(glassEffectLevelProvider);
    final base = switch (variant) {
      GlassVariant.weak => palette.glassWeak,
      GlassVariant.medium => palette.glassMedium,
      GlassVariant.strong => palette.glassStrong,
    };
    final blur = switch (variant) {
      GlassVariant.weak => ChatNuBlur.weak,
      GlassVariant.medium => ChatNuBlur.medium,
      GlassVariant.strong => ChatNuBlur.strong,
    };
    final qualityFactor = switch (effectLevel) {
      GlassEffectLevel.full => 1.0,
      GlassEffectLevel.balanced => 0.65,
      GlassEffectLevel.reduced => 0.0,
    };
    final shouldBlur = enableBlur && qualityFactor > 0;
    final radius = BorderRadius.circular(borderRadius);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              palette.borderHighlight.withValues(alpha: 0.06),
              base,
            ),
            base,
          ],
        ),
        border: Border.all(
          color: variant == GlassVariant.strong
              ? palette.borderHighlight
              : palette.borderSubtle,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.08,
            ),
            blurRadius: variant == GlassVariant.strong ? 24 : 14,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: palette.borderHighlight.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: shouldBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blur * qualityFactor,
                  sigmaY: blur * qualityFactor,
                ),
                child: content,
              )
            : content,
      ),
    );
  }
}

class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    required this.icon,
    required this.tooltip,
    super.key,
    this.onPressed,
    this.selected = false,
    this.size = 42,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final enabled = widget.onPressed != null;
    final active = widget.selected || _hovered;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
          onExit: enabled ? (_) => setState(() => _hovered = false) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: ChatNuMotion.micro,
              curve: ChatNuMotion.standard,
              child: AnimatedContainer(
                duration: ChatNuMotion.micro,
                curve: ChatNuMotion.standard,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ChatNuRadii.md),
                  color: active ? palette.glassMedium : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? palette.borderHighlight
                        : Colors.transparent,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: enabled ? palette.textSecondary : palette.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
