import 'dart:ui';

import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

enum GlassVariant { weak, medium, strong }

enum GlassEffectLevel { full, balanced, reduced }

class GlassEffectController extends Notifier<GlassEffectLevel> {
  @override
  GlassEffectLevel build() => GlassEffectLevel.full;

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = switch (variant) {
      GlassVariant.weak => palette.glassWeak,
      GlassVariant.medium => palette.glassMedium,
      GlassVariant.strong => palette.glassStrong,
    };
    final qualityFactor = switch (effectLevel) {
      GlassEffectLevel.full => 1.0,
      GlassEffectLevel.balanced => 0.58,
      GlassEffectLevel.reduced => 0.0,
    };
    final blurSigma = switch (variant) {
      GlassVariant.weak => ChatNuBlur.weak,
      GlassVariant.medium => ChatNuBlur.medium,
      GlassVariant.strong => ChatNuBlur.strong,
    };
    final shouldBlur = enableBlur && qualityFactor > 0;
    final useRefraction =
        shouldBlur &&
        effectLevel == GlassEffectLevel.full &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
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
              Colors.white.withValues(
                alpha: dark
                    ? 0.035 + (0.025 * qualityFactor)
                    : 0.1 + (0.06 * qualityFactor),
              ),
              base.withValues(alpha: dark ? 0.76 : 0.68),
            ),
            base.withValues(alpha: dark ? 0.68 : 0.78),
          ],
        ),
        border: Border.all(
          color: variant == GlassVariant.strong
              ? palette.borderHighlight.withValues(alpha: 0.9)
              : palette.borderSubtle.withValues(alpha: 0.82),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.075),
            blurRadius: variant == GlassVariant.strong ? 30 : 18,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.035 : 0.55),
            blurRadius: 1.5,
            offset: const Offset(0, -1.2),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );

    final compatibilityGlass = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: <Widget>[
          if (shouldBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigma * qualityFactor,
                  sigmaY: blurSigma * qualityFactor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const <double>[0, 0.36, 0.72, 1],
                    colors: <Color>[
                      Colors.white12,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white10,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!useRefraction) {
      return RepaintBoundary(child: compatibilityGlass);
    }

    final refraction = switch (variant) {
      GlassVariant.weak => LiquidGlassRefraction(
        distortion: 0.035,
        distortionWidth: 14,
      ),
      GlassVariant.medium => LiquidGlassRefraction(
        distortion: 0.065,
        distortionWidth: 20,
      ),
      GlassVariant.strong => LiquidGlassRefraction(
        distortion: 0.09,
        distortionWidth: 26,
      ),
    };

    return RepaintBoundary(
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          shape: LiquidGlassShape.squircle(cornerRadius: borderRadius),
          refraction: refraction,
        ),
        child: compatibilityGlass,
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
