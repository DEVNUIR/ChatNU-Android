import 'dart:async';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/core/utils/bidi.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/widgets/rich_message_content.dart';
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
    final bubbleColor = mine ? palette.accentPrimary : palette.glassWeak;
    final alignment = mine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(16),
      topEnd: const Radius.circular(16),
      bottomStart: Radius.circular(mine ? 16 : 5),
      bottomEnd: Radius.circular(mine ? 5 : 16),
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
          padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 7),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!mine && showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (message.type == ChatNuMessageType.text ||
                  message.type == ChatNuMessageType.system ||
                  (message.type == ChatNuMessageType.location &&
                      !message.hasLocation))
                Directionality(
                  textDirection: directionForText(message.body),
                  child: Text(
                    message.body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: mine ? Colors.black : palette.textPrimary,
                    ),
                  ),
                )
              else
                RichMessageContent(message: message, mine: mine),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mine
                          ? Colors.black.withValues(alpha: 0.58)
                          : palette.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                  if (mine) ...<Widget>[
                    const SizedBox(width: 5),
                    DeliveryStatus(
                      state: message.deliveryState,
                      foreground: Colors.black.withValues(alpha: 0.58),
                    ),
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
    final palette = context.chatNu;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: palette.borderHighlight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.glassWeak,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 14),
              _MessageSheetAction(
                icon: Icons.copy_outlined,
                label: strings.copy,
                onTap: () {
                  unawaited(
                    Clipboard.setData(ClipboardData(text: message.body)),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
              if (mine &&
                  message.deliveryState == MessageDeliveryState.failed &&
                  message.type == ChatNuMessageType.text) ...<Widget>[
                Divider(color: palette.borderSubtle, height: 1),
                _MessageSheetAction(
                  icon: Icons.refresh_rounded,
                  label: strings.retry,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref
                        .read(messengerDemoProvider.notifier)
                        .retryMessage(message);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageSheetAction extends StatelessWidget {
  const _MessageSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 58,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(label),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}

class DeliveryStatus extends StatelessWidget {
  const DeliveryStatus({required this.state, this.foreground, super.key});

  final MessageDeliveryState state;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final color = foreground ?? palette.textMuted;
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
        size: 13,
        color: color,
      ),
      MessageDeliveryState.sending => SizedBox.square(
        dimension: 11,
        child: CircularProgressIndicator(strokeWidth: 1.3, color: color),
      ),
      MessageDeliveryState.failed => Icon(
        Icons.error_outline,
        size: 14,
        color: foreground ?? palette.destructive,
      ),
      MessageDeliveryState.sentToServer ||
      MessageDeliveryState.deliveredToRecipientDevice ||
      MessageDeliveryState.read => Icon(
        Icons.done_all_rounded,
        size: 14,
        color: color,
      ),
    };
    return Tooltip(
      message: label,
      child: Semantics(label: label, child: child),
    );
  }
}
