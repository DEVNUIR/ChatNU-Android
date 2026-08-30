import 'dart:async';

import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/core/utils/bidi.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:chatnu/features/messages/presentation/message_grouping.dart';
import 'package:chatnu/features/messages/presentation/widgets/rich_message_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _MessageAction { copy, retry }

class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.message,
    required this.mine,
    required this.showSender,
    super.key,
    this.groupPosition = MessageGroupPosition.single,
    this.senderAvatarUrl,
    this.showAvatar = false,
    this.reserveAvatarSpace = false,
    this.searchQuery = '',
    this.searchSelected = false,
  });

  final ChatNuMessage message;
  final bool mine;
  final bool showSender;
  final MessageGroupPosition groupPosition;
  final String? senderAvatarUrl;
  final bool showAvatar;
  final bool reserveAvatarSpace;
  final String searchQuery;
  final bool searchSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.chatNu;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(message.sentAt.toLocal()),
      alwaysUse24HourFormat: true,
    );
    final bubbleColor = mine ? palette.accentPrimary : palette.glassWeak;
    final alignment = mine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final groupedEnd = MessageGrouping.isGroupEnd(groupPosition);
    final bubble = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        unawaited(HapticFeedback.mediumImpact());
        unawaited(_showMobileActions(context, ref));
      },
      onSecondaryTapDown: (details) => unawaited(
        _showDesktopActions(context, ref, details.globalPosition),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: ChatNuSizing.messageMaxWidth),
        margin: EdgeInsetsDirectional.only(bottom: groupedEnd ? 7 : 2),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: _bubbleRadius(),
          border: searchSelected
              ? Border.all(
                  color: mine
                      ? Colors.black.withValues(alpha: 0.32)
                      : palette.accentPrimary.withValues(alpha: 0.72),
                  width: 1.4,
                )
              : null,
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
                child: _MessageText(
                  text: message.body,
                  query: searchQuery,
                  mine: mine,
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
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              ChatNuSizing.messageMaxWidth +
              (!mine && reserveAvatarSpace ? 40 : 0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            if (!mine && reserveAvatarSpace) ...<Widget>[
              SizedBox.square(
                dimension: 32,
                child: showAvatar
                    ? GlassAvatar(
                        label: message.senderName,
                        imageUrl: senderAvatarUrl,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

  BorderRadiusDirectional _bubbleRadius() {
    const outer = Radius.circular(16);
    const joined = Radius.circular(6);
    const tail = Radius.circular(5);

    if (mine) {
      return switch (groupPosition) {
        MessageGroupPosition.single => const BorderRadiusDirectional.only(
          topStart: outer,
          topEnd: outer,
          bottomStart: outer,
          bottomEnd: tail,
        ),
        MessageGroupPosition.first => const BorderRadiusDirectional.only(
          topStart: outer,
          topEnd: outer,
          bottomStart: outer,
          bottomEnd: joined,
        ),
        MessageGroupPosition.middle => const BorderRadiusDirectional.only(
          topStart: outer,
          topEnd: joined,
          bottomStart: outer,
          bottomEnd: joined,
        ),
        MessageGroupPosition.last => const BorderRadiusDirectional.only(
          topStart: outer,
          topEnd: joined,
          bottomStart: outer,
          bottomEnd: tail,
        ),
      };
    }

    return switch (groupPosition) {
      MessageGroupPosition.single => const BorderRadiusDirectional.only(
        topStart: outer,
        topEnd: outer,
        bottomStart: tail,
        bottomEnd: outer,
      ),
      MessageGroupPosition.first => const BorderRadiusDirectional.only(
        topStart: outer,
        topEnd: outer,
        bottomStart: joined,
        bottomEnd: outer,
      ),
      MessageGroupPosition.middle => const BorderRadiusDirectional.only(
        topStart: joined,
        topEnd: outer,
        bottomStart: joined,
        bottomEnd: outer,
      ),
      MessageGroupPosition.last => const BorderRadiusDirectional.only(
        topStart: joined,
        topEnd: outer,
        bottomStart: tail,
        bottomEnd: outer,
      ),
    };
  }

  List<_MessageAction> get _actions {
    final actions = <_MessageAction>[];
    if (message.body.trim().isNotEmpty) actions.add(_MessageAction.copy);
    if (mine &&
        message.deliveryState == MessageDeliveryState.failed &&
        message.type == ChatNuMessageType.text) {
      actions.add(_MessageAction.retry);
    }
    return actions;
  }

  Future<void> _showMobileActions(BuildContext context, WidgetRef ref) async {
    final actions = _actions;
    if (actions.isEmpty) return;
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
                  _previewText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < actions.length; index++) ...<Widget>[
                if (index > 0) Divider(color: palette.borderSubtle, height: 1),
                _MessageSheetAction(
                  icon: _iconFor(actions[index]),
                  label: _labelFor(actions[index], strings),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _performAction(actions[index], ref);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDesktopActions(
    BuildContext context,
    WidgetRef ref,
    Offset globalPosition,
  ) async {
    final actions = _actions;
    if (actions.isEmpty) return;
    final strings = ChatNuStrings.of(context);
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final selected = await showMenu<_MessageAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: actions
          .map(
            (action) => PopupMenuItem<_MessageAction>(
              value: action,
              child: Row(
                children: <Widget>[
                  Icon(_iconFor(action), size: 19),
                  const SizedBox(width: 10),
                  Text(_labelFor(action, strings)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) _performAction(selected, ref);
  }

  void _performAction(_MessageAction action, WidgetRef ref) {
    switch (action) {
      case _MessageAction.copy:
        unawaited(Clipboard.setData(ClipboardData(text: message.body)));
      case _MessageAction.retry:
        ref.read(messengerDemoProvider.notifier).retryMessage(message);
    }
  }

  IconData _iconFor(_MessageAction action) => switch (action) {
    _MessageAction.copy => Icons.copy_outlined,
    _MessageAction.retry => Icons.refresh_rounded,
  };

  String _labelFor(_MessageAction action, ChatNuStrings strings) =>
      switch (action) {
        _MessageAction.copy => strings.copy,
        _MessageAction.retry => strings.retry,
      };

  String get _previewText {
    final body = message.body.trim();
    if (body.isNotEmpty) return body;
    final fileName = message.fileName?.trim();
    if (fileName != null && fileName.isNotEmpty) return fileName;
    return message.type.name;
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText({
    required this.text,
    required this.query,
    required this.mine,
  });

  final String text;
  final String query;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: mine ? Colors.black : palette.textPrimary,
    );
    final needle = query.trim();
    if (needle.isEmpty || text.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final sourceLower = text.toLowerCase();
    final needleLower = needle.toLowerCase();
    final spans = <InlineSpan>[];
    var cursor = 0;
    while (cursor < text.length) {
      final match = sourceLower.indexOf(needleLower, cursor);
      if (match < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      if (match > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match)));
      }
      final end = match + needle.length;
      spans.add(
        TextSpan(
          text: text.substring(match, end),
          style: baseStyle?.copyWith(
            backgroundColor: mine
                ? Colors.black.withValues(alpha: 0.12)
                : palette.accentPrimary.withValues(alpha: 0.28),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = end;
    }
    if (spans.isEmpty) return Text(text, style: baseStyle);
    return Text.rich(TextSpan(style: baseStyle, children: spans));
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
      MessageDeliveryState.queuedOffline => strings.queued,
      MessageDeliveryState.sending => strings.sending,
      MessageDeliveryState.failed => strings.failed,
      MessageDeliveryState.sentToServer ||
      MessageDeliveryState.deliveredToRecipientDevice ||
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
      // The current server proves acknowledgement only. Do not imply device
      // delivery/read with double-check semantics until a real receipt exists.
      MessageDeliveryState.sentToServer ||
      MessageDeliveryState.deliveredToRecipientDevice ||
      MessageDeliveryState.read => Icon(
        Icons.done_rounded,
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
