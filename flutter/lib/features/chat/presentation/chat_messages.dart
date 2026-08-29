import 'dart:async';

import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/responsive/chatnu_breakpoints.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/core/utils/bidi.dart';
import 'package:chatnu/features/chat/domain/chat_models.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    required this.messages,
    required this.modelName,
    required this.controller,
    super.key,
  });

  final List<ChatMessage> messages;
  final String modelName;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        ChatNuSpacing.md,
        ChatNuSpacing.lg,
        ChatNuSpacing.md,
        132,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ChatNuBreakpoints.conversationMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: ChatNuSpacing.xl),
              child: message.role == ChatMessageRole.user
                  ? _UserMessage(message: message)
                  : _AssistantMessage(message: message, modelName: modelName),
            ),
          ),
        );
      },
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: GlassSurface(
          variant: GlassVariant.medium,
          borderRadius: ChatNuRadii.lg,
          padding: const EdgeInsets.symmetric(
            horizontal: ChatNuSpacing.md,
            vertical: ChatNuSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Directionality(
                textDirection: directionForText(message.markdown),
                child: SelectableText(
                  message.markdown,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: ChatNuSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  message.timestamp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.message, required this.modelName});

  final ChatMessage message;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: ChatNuMark(size: 32),
        ),
        const SizedBox(width: ChatNuSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('ChatNU', style: theme.textTheme.titleMedium),
                  const SizedBox(width: ChatNuSpacing.xs),
                  Text(
                    modelName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    message.timestamp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ChatNuSpacing.sm),
              Directionality(
                textDirection: directionForText(message.markdown),
                child: MarkdownBody(
                  data: message.markdown,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                      height: 1.6,
                    ),
                    strong: theme.textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    code: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: palette.accentPrimary,
                    ),
                  ),
                ),
              ),
              if (message.code case final code?) ...<Widget>[
                const SizedBox(height: ChatNuSpacing.md),
                PremiumCodeBlock(
                  code: code,
                  language: message.codeLanguage ?? 'text',
                ),
              ],
              const SizedBox(height: ChatNuSpacing.sm),
              Wrap(
                spacing: ChatNuSpacing.xs,
                children: <Widget>[
                  _MessageAction(icon: Icons.copy_rounded, label: 'Copy'),
                  _MessageAction(
                    icon: Icons.refresh_rounded,
                    label: 'Regenerate',
                  ),
                  _MessageAction(icon: Icons.more_horiz_rounded, label: 'More'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Tooltip(
      message: '$label — wired in a later phase',
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: palette.textMuted),
      ),
    );
  }
}

class PremiumCodeBlock extends StatefulWidget {
  const PremiumCodeBlock({
    required this.code,
    required this.language,
    super.key,
  });

  final String code;
  final String language;

  @override
  State<PremiumCodeBlock> createState() => _PremiumCodeBlockState();
}

class _PremiumCodeBlockState extends State<PremiumCodeBlock> {
  final ScrollController _scrollController = ScrollController();
  List<InlineSpan> _highlighted = const <InlineSpan>[];
  bool _copied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _highlighted = _highlight(widget.code, context);
  }

  @override
  void didUpdateWidget(covariant PremiumCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code) {
      _highlighted = _highlight(widget.code, context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copy() {
    unawaited(Clipboard.setData(ClipboardData(text: widget.code)));
    setState(() => _copied = true);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1300)).then((_) {
        if (mounted) setState(() => _copied = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: palette.backgroundSecondary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.language.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _copy,
                    icon: AnimatedSwitcher(
                      duration: ChatNuMotion.micro,
                      child: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        key: ValueKey<bool>(_copied),
                        size: 16,
                      ),
                    ),
                    label: Text(_copied ? 'Copied' : 'Copy'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.borderSubtle),
            Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(ChatNuSpacing.md),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText.rich(
                    TextSpan(children: _highlighted),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<InlineSpan> _highlight(String code, BuildContext context) {
  final palette = context.chatNu;
  final base = TextStyle(
    color: palette.textPrimary,
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.55,
  );
  final pattern = RegExp(
    r'''//[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:class|const|final|required|static|return|double|void|Widget|BuildContext)\b''',
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in pattern.allMatches(code)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: code.substring(cursor, match.start), style: base),
      );
    }
    final token = match.group(0)!;
    final color = token.startsWith('//')
        ? palette.textMuted
        : token.startsWith('"') || token.startsWith("'")
        ? palette.success
        : palette.accentPrimary;
    spans.add(
      TextSpan(
        text: token,
        style: base.copyWith(color: color),
      ),
    );
    cursor = match.end;
  }
  if (cursor < code.length) {
    spans.add(TextSpan(text: code.substring(cursor), style: base));
  }
  return spans;
}
