import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
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

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 8, 9),
        decoration: BoxDecoration(
          color: palette.backgroundElevated,
          border: Border(top: BorderSide(color: palette.borderSubtle)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton(
              key: const Key('message-attach-button'),
              tooltip: strings.attach,
              onPressed: demo ? null : () => unawaited(_pickAttachment()),
              icon: const Icon(Icons.add_rounded, size: 28),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: palette.glassWeak,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 132),
                  child: TextField(
                    key: const Key('message-composer-field'),
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: strings.messageHint,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: canSend
                  ? IconButton.filled(
                      key: const Key('message-send-button'),
                      tooltip: strings.send,
                      style: IconButton.styleFrom(
                        backgroundColor: palette.textPrimary,
                        foregroundColor: palette.backgroundElevated,
                        minimumSize: const Size(46, 46),
                      ),
                      onPressed: _send,
                      icon: const Icon(Icons.arrow_upward_rounded, size: 22),
                    )
                  : SizedBox(
                      key: const ValueKey<String>('composer-idle'),
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 19,
                        color: palette.textMuted,
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
