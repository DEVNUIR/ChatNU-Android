import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    required this.controller,
    required this.conversationId,
    super.key,
  });

  final TextEditingController controller;
  final String conversationId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final demo = ref.watch(appModeProvider) == ChatNuAppMode.demo;
    final canSend = widget.controller.text.trim().isNotEmpty;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        ChatNuSpacing.sm,
        ChatNuSpacing.xs,
        ChatNuSpacing.sm,
        ChatNuSpacing.sm,
      ),
      child: GlassSurface(
        variant: GlassVariant.strong,
        enableBlur: true,
        borderRadius: ChatNuRadii.xl,
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            GlassIconButton(
              icon: Icons.attach_file_rounded,
              tooltip: strings.attach,
              onPressed: demo ? null : () => unawaited(_pickAttachment()),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 144),
                child: TextField(
                  key: const Key('message-composer-field'),
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: strings.messageHint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ChatNuSpacing.sm,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              enabled: canSend,
              label: strings.send,
              child: Tooltip(
                message: strings.send,
                child: AnimatedScale(
                  duration: reduceMotion ? Duration.zero : ChatNuMotion.micro,
                  scale: canSend ? 1 : 0.94,
                  child: Material(
                    color: canSend
                        ? palette.accentPrimary
                        : palette.glassMedium,
                    borderRadius: BorderRadius.circular(ChatNuRadii.md),
                    child: InkWell(
                      key: const Key('message-send-button'),
                      borderRadius: BorderRadius.circular(ChatNuRadii.md),
                      onTap: canSend ? _send : null,
                      child: SizedBox.square(
                        dimension: ChatNuSizing.minTouchTarget,
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: canSend ? Colors.white : palette.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final value = widget.controller.text;
    if (value.trim().isEmpty) return;
    ref
        .read(messengerDemoProvider.notifier)
        .sendText(widget.conversationId, value);
    widget.controller.clear();
  }

  Future<void> _pickAttachment() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mimeType =
        lookupMimeType(file.name, headerBytes: bytes) ??
        'application/octet-stream';
    final type = mimeType.startsWith('image/')
        ? ChatNuMessageType.image
        : mimeType.startsWith('video/')
        ? ChatNuMessageType.video
        : mimeType.startsWith('audio/')
        ? ChatNuMessageType.voice
        : ChatNuMessageType.file;
    await ref
        .read(messengerDemoProvider.notifier)
        .sendAttachment(
          conversationId: widget.conversationId,
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
          type: type,
        );
  }
}
