import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:flutter/material.dart';

/// Cheap atmospheric background: gradients only, no full-screen blur shader.
class ChatNuAtmosphere extends StatelessWidget {
  const ChatNuAtmosphere({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: palette.backgroundPrimary,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const AlignmentDirectional(0.85, -0.95),
                  radius: 1.1,
                  colors: <Color>[
                    palette.accentPrimary.withValues(alpha: dark ? 0.16 : 0.11),
                    Colors.transparent,
                  ],
                  stops: const <double>[0, 0.72],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const AlignmentDirectional(-1.1, 1.05),
                  radius: 1.15,
                  colors: <Color>[
                    palette.accentSecondary.withValues(
                      alpha: dark ? 0.09 : 0.055,
                    ),
                    Colors.transparent,
                  ],
                  stops: const <double>[0, 0.66],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    required this.body,
    super.key,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: ChatNuAtmosphere(child: body),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
    this.variant = GlassVariant.medium,
    this.blur = false,
    this.radius = ChatNuRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final GlassVariant variant;
  final bool blur;
  final double radius;

  @override
  Widget build(BuildContext context) => GlassSurface(
    variant: variant,
    enableBlur: blur,
    borderRadius: radius,
    padding: padding,
    child: child,
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(ChatNuSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) =>
      GlassPanel(variant: GlassVariant.weak, padding: padding, child: child);
}

class GlassAppBar extends StatelessWidget {
  const GlassAppBar({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ChatNuSpacing.sm,
        ChatNuSpacing.sm,
        ChatNuSpacing.sm,
        ChatNuSpacing.xs,
      ),
      child: GlassSurface(
        enableBlur: true,
        variant: GlassVariant.medium,
        borderRadius: ChatNuRadii.lg,
        padding: const EdgeInsets.symmetric(
          horizontal: ChatNuSpacing.xs,
          vertical: ChatNuSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: ChatNuSpacing.xs),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[title, ?subtitle],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        ChatNuSpacing.sm,
        0,
        ChatNuSpacing.sm,
        ChatNuSpacing.sm,
      ),
      child: GlassSurface(
        variant: GlassVariant.strong,
        enableBlur: true,
        borderRadius: ChatNuRadii.xl,
        padding: const EdgeInsets.all(ChatNuSpacing.xs),
        child: child,
      ),
    );
  }
}

class GlassNavigationRail extends StatelessWidget {
  const GlassNavigationRail({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(ChatNuSpacing.sm),
      child: SizedBox(
        width: ChatNuSizing.navigationRail,
        child: GlassSurface(
          variant: GlassVariant.medium,
          enableBlur: true,
          borderRadius: ChatNuRadii.xl,
          padding: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.xs,
            vertical: ChatNuSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.prominent = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool prominent;
  final bool destructive;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final enabled = widget.onPressed != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final foreground = widget.prominent || widget.destructive
        ? Colors.white
        : palette.textPrimary;
    final baseBackground = widget.destructive
        ? palette.destructive
        : widget.prominent
        ? palette.accentPrimary
        : palette.glassMedium;
    final background = enabled && (_hovered || _focused)
        ? Color.alphaBlend(
            palette.textPrimary.withValues(alpha: _focused ? 0.06 : 0.035),
            baseBackground,
          )
        : baseBackground;
    final borderColor = _focused
        ? palette.accentPrimary
        : widget.prominent || widget.destructive
        ? Colors.white.withValues(alpha: 0.14)
        : palette.borderSubtle;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            onTap: widget.onPressed,
            canRequestFocus: enabled,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onHighlightChanged: enabled
                ? (value) => setState(() => _pressed = value)
                : null,
            onHover: enabled
                ? (value) => setState(() => _hovered = value)
                : null,
            onFocusChange: enabled
                ? (value) => setState(() => _focused = value)
                : null,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedScale(
              scale: _pressed && !reduceMotion ? 0.98 : 1,
              duration: reduceMotion ? Duration.zero : ChatNuMotion.micro,
              curve: ChatNuMotion.standard,
              child: AnimatedOpacity(
                duration: reduceMotion ? Duration.zero : ChatNuMotion.micro,
                opacity: enabled ? 1 : 0.46,
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : ChatNuMotion.micro,
                  constraints: const BoxConstraints(
                    minHeight: ChatNuSizing.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(ChatNuRadii.md),
                    border: Border.all(
                      color: borderColor,
                      width: _focused ? 1.5 : 1,
                    ),
                    boxShadow: _focused
                        ? <BoxShadow>[
                            BoxShadow(
                              color: palette.accentPrimary.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 14,
                            ),
                          ]
                        : widget.prominent
                        ? <BoxShadow>[
                            BoxShadow(
                              color: palette.accentPrimary.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        Icon(widget.icon, size: 19, color: foreground),
                        const SizedBox(width: ChatNuSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSearchField extends StatefulWidget {
  const GlassSearchField({
    required this.controller,
    required this.hintText,
    super.key,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<GlassSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant GlassSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : ChatNuMotion.micro,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        boxShadow: _focusNode.hasFocus
            ? <BoxShadow>[
                BoxShadow(
                  color: palette.accentPrimary.withValues(alpha: 0.13),
                  blurRadius: 18,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    required this.controller,
    super.key,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    minLines: obscureText ? 1 : minLines,
    maxLines: obscureText ? 1 : maxLines,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(labelText: labelText, hintText: hintText),
  );
}

class GlassAvatar extends StatelessWidget {
  const GlassAvatar({
    required this.label,
    super.key,
    this.imageUrl,
    this.group = false,
    this.size = ChatNuSizing.avatar,
  });

  final String label;
  final String? imageUrl;
  final bool group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final initial = label.trim().isEmpty ? '?' : label.trim().characters.first;
    return Semantics(
      image: true,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.glassStrong,
          border: Border.all(color: palette.borderHighlight),
          image: imageUrl == null || imageUrl!.isEmpty
              ? null
              : DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                ),
        ),
        alignment: Alignment.center,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? null
            : group
            ? Icon(Icons.group_outlined, color: palette.textPrimary)
            : Text(
                initial.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
      ),
    );
  }
}

class GlassBadge extends StatelessWidget {
  const GlassBadge({required this.label, super.key, this.semanticLabel});

  final String label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: palette.accentPrimary,
          borderRadius: BorderRadius.circular(ChatNuRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class GlassSegmentedControl<T> extends StatelessWidget {
  const GlassSegmentedControl({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: GlassSurface(
        variant: GlassVariant.weak,
        borderRadius: ChatNuRadii.pill,
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items.entries
              .map((entry) {
                final selected = entry.key == value;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 2),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: entry.value,
                    onTap: () => onChanged(entry.key),
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(ChatNuRadii.pill),
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => onChanged(entry.key),
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : ChatNuMotion.micro,
                        constraints: const BoxConstraints(
                          minHeight: ChatNuSizing.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: ChatNuSpacing.sm,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? palette.glassStrong
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(ChatNuRadii.pill),
                          border: Border.all(
                            color: selected
                                ? palette.borderHighlight
                                : Colors.transparent,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.value,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selected
                                    ? palette.textPrimary
                                    : palette.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class GlassDialog extends StatelessWidget {
  const GlassDialog({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    elevation: 0,
    backgroundColor: Colors.transparent,
    child: GlassSurface(
      variant: GlassVariant.strong,
      enableBlur: true,
      borderRadius: ChatNuRadii.xl,
      padding: const EdgeInsets.all(ChatNuSpacing.md),
      child: child,
    ),
  );
}

class GlassSheet extends StatelessWidget {
  const GlassSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: GlassSurface(
      variant: GlassVariant.strong,
      enableBlur: true,
      borderRadius: ChatNuRadii.xl,
      padding: const EdgeInsets.all(ChatNuSpacing.md),
      child: child,
    ),
  );
}

class GlassMenu extends StatelessWidget {
  const GlassMenu({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => GlassSurface(
    variant: GlassVariant.strong,
    enableBlur: true,
    borderRadius: ChatNuRadii.md,
    padding: const EdgeInsets.all(ChatNuSpacing.xs),
    child: child,
  );
}

class GlassContextMenu extends GlassMenu {
  const GlassContextMenu({required super.child, super.key});
}
