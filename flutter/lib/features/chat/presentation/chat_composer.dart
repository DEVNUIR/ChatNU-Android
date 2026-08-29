import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/chat/application/chat_demo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({
    required this.onSent,
    required this.onAttachmentPressed,
    super.key,
  });

  final VoidCallback onSent;
  final VoidCallback onAttachmentPressed;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    _controller.addListener(_handleText);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller
      ..removeListener(_handleText)
      ..dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _handleText() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    ref.read(chatDemoControllerProvider.notifier).send(text);
    _controller.clear();
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return AnimatedPadding(
      duration: ChatNuMotion.component,
      curve: ChatNuMotion.standard,
      padding: EdgeInsets.symmetric(horizontal: _focused ? 0 : 2),
      child: GlassSurface(
        variant: GlassVariant.strong,
        borderRadius: ChatNuRadii.xl,
        enableBlur: true,
        padding: const EdgeInsets.all(ChatNuSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            GlassIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Attach file',
              onPressed: widget.onAttachmentPressed,
            ),
            const SizedBox(width: ChatNuSpacing.xs),
            Expanded(
              child: TextField(
                key: const Key('chat-composer-field'),
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Message ChatNU',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.xs,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: ChatNuSpacing.xs),
            GlassIconButton(
              icon: Icons.mic_none_rounded,
              tooltip: 'Voice input — future phase',
            ),
            const SizedBox(width: ChatNuSpacing.xs),
            _SendButton(enabled: _hasText, onPressed: _send),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Send message',
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: ChatNuMotion.micro,
            curve: ChatNuMotion.standard,
            child: AnimatedContainer(
              key: const Key('chat-send-button'),
              duration: ChatNuMotion.micro,
              curve: ChatNuMotion.standard,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ChatNuRadii.md),
                gradient: enabled
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          palette.accentPrimary,
                          palette.accentSecondary,
                        ],
                      )
                    : null,
                color: enabled ? null : palette.glassWeak,
                boxShadow: enabled && _hovered
                    ? <BoxShadow>[
                        BoxShadow(
                          color: palette.accentPrimary.withValues(alpha: 0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 21,
                color: enabled ? Colors.white : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
