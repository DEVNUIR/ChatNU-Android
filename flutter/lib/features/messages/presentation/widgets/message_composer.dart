import 'dart:async';
import 'dart:ui';

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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 9, 8, 9),
            decoration: BoxDecoration(
              color: palette.backgroundElevated.withValues(alpha: 0.82),
              border: Border(top: BorderSide(color: palette.borderSubtle)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  key: const Key('message-attach-button'),
                  tooltip: strings.attach,
                  onPressed: demo
                      ? null
                      : () => unawaited(_showAttachmentSheet()),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(46, 46),
                    backgroundColor: palette.glassWeak,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 27),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.backgroundElevated.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: palette.borderSubtle),
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
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 22,
                          ),
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

  Future<void> _showAttachmentSheet() async {
    FocusScope.of(context).unfocus();
    final palette = context.chatNu;
    final persian = Localizations.localeOf(context).languageCode == 'fa';
    final choice = await showModalBottomSheet<_AttachmentChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
        decoration: BoxDecoration(
          color: palette.backgroundElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: palette.borderHighlight,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AttachmentAction(
                    icon: Icons.photo_rounded,
                    label: persian ? 'عکس' : 'Photo',
                    onTap: () =>
                        Navigator.of(context).pop(_AttachmentChoice.photo),
                  ),
                ),
                Expanded(
                  child: _AttachmentAction(
                    icon: Icons.videocam_rounded,
                    label: persian ? 'ویدیو' : 'Video',
                    onTap: () =>
                        Navigator.of(context).pop(_AttachmentChoice.video),
                  ),
                ),
                Expanded(
                  child: _AttachmentAction(
                    icon: Icons.graphic_eq_rounded,
                    label: persian ? 'صدا' : 'Audio',
                    onTap: () =>
                        Navigator.of(context).pop(_AttachmentChoice.audio),
                  ),
                ),
                Expanded(
                  child: _AttachmentAction(
                    icon: Icons.insert_drive_file_outlined,
                    label: persian ? 'فایل' : 'File',
                    onTap: () =>
                        Navigator.of(context).pop(_AttachmentChoice.file),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _pickAttachment(choice.fileType);
  }

  Future<void> _pickAttachment(FileType fileType) async {
    final file = await FilePicker.pickFile(type: fileType);
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

enum _AttachmentChoice { photo, video, audio, file }

extension on _AttachmentChoice {
  FileType get fileType => switch (this) {
    _AttachmentChoice.photo => FileType.image,
    _AttachmentChoice.video => FileType.video,
    _AttachmentChoice.audio => FileType.audio,
    _AttachmentChoice.file => FileType.any,
  };
}

class _AttachmentAction extends StatelessWidget {
  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: palette.glassMedium,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 23),
              ),
              const SizedBox(height: 7),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
