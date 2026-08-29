import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/core/utils/bidi.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.mine,
    required this.showSender,
    super.key,
  });

  final ChatNuMessage message;
  final bool mine;
  final bool showSender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.chatNu;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(message.sentAt),
      alwaysUse24HourFormat: true,
    );
    final bubbleColor = mine
        ? Color.alphaBlend(
            palette.accentPrimary.withValues(alpha: 0.3),
            palette.glassMedium,
          )
        : palette.glassMedium;
    final alignment = mine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(ChatNuRadii.md),
      topEnd: const Radius.circular(ChatNuRadii.md),
      bottomStart: Radius.circular(mine ? ChatNuRadii.md : 5),
      bottomEnd: Radius.circular(mine ? 5 : ChatNuRadii.md),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () => _showActions(context, ref),
        onSecondaryTapDown: (_) => _showActions(context, ref),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: ChatNuSizing.messageMaxWidth,
          ),
          margin: const EdgeInsetsDirectional.only(bottom: 6),
          padding: const EdgeInsetsDirectional.fromSTEB(
            ChatNuSpacing.sm,
            ChatNuSpacing.xs,
            ChatNuSpacing.sm,
            6,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            border: Border.all(
              color: mine
                  ? palette.accentPrimary.withValues(alpha: 0.22)
                  : palette.borderSubtle,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!mine && showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.accentPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (message.type == ChatNuMessageType.text ||
                  !message.hasAttachment)
                Directionality(
                  textDirection: directionForText(message.body),
                  child: SelectableText(
                    message.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                _AttachmentContent(message: message),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(time, style: Theme.of(context).textTheme.bodySmall),
                  if (mine) ...<Widget>[
                    const SizedBox(width: 5),
                    DeliveryStatus(state: message.deliveryState),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final strings = ChatNuStrings.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GlassSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(strings.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.body));
                Navigator.of(sheetContext).pop();
              },
            ),
            if (mine &&
                message.deliveryState == MessageDeliveryState.failed &&
                message.type == ChatNuMessageType.text)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(strings.retry),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(messengerDemoProvider.notifier)
                      .retryMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentContent extends ConsumerWidget {
  const _AttachmentContent({required this.message});

  final ChatNuMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.glassStrong,
              borderRadius: BorderRadius.circular(ChatNuRadii.sm),
              border: Border.all(color: palette.borderSubtle),
            ),
            alignment: Alignment.center,
            child: Icon(_attachmentIcon(message.type)),
          ),
          const SizedBox(width: ChatNuSpacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.fileName ?? message.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (message.sizeBytes != null)
                  Text(
                    _formatBytes(message.sizeBytes!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (message.hasAttachment)
            IconButton(
              tooltip: strings.attachmentDownload,
              onPressed: () => unawaited(_download(context, ref)),
              icon: const Icon(Icons.download_rounded),
            )
          else if (message.deliveryState == MessageDeliveryState.sending)
            const Padding(
              padding: EdgeInsets.all(ChatNuSpacing.sm),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final strings = ChatNuStrings.of(context);
    final bytes = await ref
        .read(messengerDemoProvider.notifier)
        .downloadAttachment(message);
    if (bytes == null || !context.mounted) return;
    final result = await FilePicker.saveFile(
      dialogTitle: strings.attachmentDownload,
      fileName: message.fileName ?? 'attachment',
      bytes: bytes,
      mimeType: message.mimeType ?? 'application/octet-stream',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null ? strings.saveCancelled : strings.attachmentSaved,
        ),
      ),
    );
  }

  static IconData _attachmentIcon(ChatNuMessageType type) => switch (type) {
    ChatNuMessageType.image ||
    ChatNuMessageType.viewOnceImage => Icons.image_outlined,
    ChatNuMessageType.video ||
    ChatNuMessageType.viewOnceVideo => Icons.video_file_outlined,
    ChatNuMessageType.voice => Icons.audio_file_outlined,
    _ => Icons.insert_drive_file_outlined,
  };

  static String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KiB';
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
}

class DeliveryStatus extends StatelessWidget {
  const DeliveryStatus({required this.state, super.key});

  final MessageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final label = switch (state) {
      MessageDeliveryState.queuedOffline => strings.sending,
      MessageDeliveryState.sending => strings.sending,
      MessageDeliveryState.failed => strings.failed,
      MessageDeliveryState.sentToServer => strings.sentToServer,
      MessageDeliveryState.deliveredToRecipientDevice => strings.sentToServer,
      MessageDeliveryState.read => strings.sentToServer,
    };
    final child = switch (state) {
      MessageDeliveryState.queuedOffline => Icon(
        Icons.schedule_rounded,
        size: 14,
        color: palette.textMuted,
      ),
      MessageDeliveryState.sending => SizedBox.square(
        dimension: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.4,
          color: palette.textMuted,
        ),
      ),
      MessageDeliveryState.failed => Icon(
        Icons.error_outline,
        size: 15,
        color: palette.destructive,
      ),
      MessageDeliveryState.sentToServer ||
      MessageDeliveryState.deliveredToRecipientDevice ||
      MessageDeliveryState.read => Icon(
        Icons.check_rounded,
        size: 15,
        color: palette.textMuted,
      ),
    };
    return Tooltip(
      message: label,
      child: Semantics(label: label, child: child),
    );
  }
}
