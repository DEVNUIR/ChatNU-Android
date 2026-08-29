import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/product/chatnu_capabilities.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/core/utils/bidi.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/domain/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationPane extends ConsumerStatefulWidget {
  const ConversationPane({
    required this.conversationId,
    super.key,
    this.onBack,
  });

  final String conversationId;
  final VoidCallback? onBack;

  @override
  ConsumerState<ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<ConversationPane> {
  final _composerController = TextEditingController();

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messengerDemoProvider);
    final conversation = state.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    if (conversation == null) {
      return const SizedBox.shrink();
    }
    final messages = state.messagesByConversation[conversation.id] ??
        const <ChatNuMessage>[];
    final palette = context.chatNu;

    return ColoredBox(
      color: palette.backgroundPrimary,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _ConversationHeader(
              conversation: conversation,
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView.builder(
                key: const Key('message-list'),
                reverse: true,
                padding: const EdgeInsets.fromLTRB(
                  ChatNuSpacing.md,
                  ChatNuSpacing.md,
                  ChatNuSpacing.md,
                  ChatNuSpacing.xl,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return _MessageBubble(
                    message: message,
                    mine: message.senderId == state.currentUser.id,
                    showSender: conversation.kind == ConversationKind.group,
                  );
                },
              ),
            ),
            _Composer(
              controller: _composerController,
              conversationId: conversation.id,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.conversation, this.onBack});

  final ChatNuConversation conversation;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final isDirect = conversation.kind == ConversationKind.direct;
    return Padding(
      padding: const EdgeInsets.all(ChatNuSpacing.sm),
      child: GlassSurface(
        variant: GlassVariant.medium,
        enableBlur: true,
        borderRadius: ChatNuRadii.lg,
        padding: const EdgeInsets.symmetric(
          horizontal: ChatNuSpacing.xs,
          vertical: ChatNuSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            if (onBack != null)
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: strings.back,
                onPressed: onBack,
              ),
            CircleAvatar(
              radius: 20,
              backgroundColor: palette.glassStrong,
              child: isDirect
                  ? Text(
                      conversation.title.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : const Icon(Icons.group_outlined),
            ),
            const SizedBox(width: ChatNuSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    isDirect
                        ? strings.encrypted
                        : strings.members(conversation.members.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isDirect && ChatNuCapabilities.current.oneToOneCalls) ...<Widget>[
              GlassIconButton(
                icon: Icons.call_outlined,
                tooltip: strings.voiceCall,
                onPressed: () => _showLocalOnly(context, strings.callMock),
              ),
              GlassIconButton(
                icon: Icons.videocam_outlined,
                tooltip: strings.videoCall,
                onPressed: () => _showLocalOnly(context, strings.callMock),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showSender,
  });

  final ChatNuMessage message;
  final bool mine;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(message.sentAt),
      alwaysUse24HourFormat: true,
    );
    final bubbleColor = mine
        ? palette.accentPrimary.withValues(alpha: 0.23)
        : palette.glassMedium;
    final alignment = mine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: ChatNuSpacing.sm,
          vertical: ChatNuSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          border: Border.all(color: palette.borderSubtle),
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
            Directionality(
              textDirection: directionForText(message.body),
              child: Text(
                message.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(time, style: Theme.of(context).textTheme.bodySmall),
                if (mine) ...<Widget>[
                  const SizedBox(width: 5),
                  _DeliveryIcon(state: message.deliveryState),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({required this.state});

  final MessageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return switch (state) {
      MessageDeliveryState.queuedOffline =>
        Icon(Icons.schedule_rounded, size: 14, color: palette.textMuted),
      MessageDeliveryState.sending => SizedBox.square(
          dimension: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.4,
            color: palette.textMuted,
          ),
        ),
      MessageDeliveryState.failed =>
        Icon(Icons.error_outline, size: 15, color: palette.destructive),
      MessageDeliveryState.sentToServer ||
      MessageDeliveryState.deliveredToRecipientDevice ||
      MessageDeliveryState.read =>
        Icon(Icons.check_rounded, size: 15, color: palette.textMuted),
    };
  }
}

class _Composer extends ConsumerWidget {
  const _Composer({
    required this.controller,
    required this.conversationId,
  });

  final TextEditingController controller;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatNuSpacing.sm,
        0,
        ChatNuSpacing.sm,
        ChatNuSpacing.sm,
      ),
      child: GlassSurface(
        variant: GlassVariant.strong,
        enableBlur: true,
        borderRadius: ChatNuRadii.lg,
        padding: const EdgeInsets.all(ChatNuSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            GlassIconButton(
              icon: Icons.attach_file_rounded,
              tooltip: strings.attach,
              onPressed: () => _showLocalOnly(context, strings.attachmentMock),
            ),
            Expanded(
              child: TextField(
                key: const Key('message-composer-field'),
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: strings.messageHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChatNuSpacing.sm,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(ref),
              ),
            ),
            IconButton.filled(
              key: const Key('message-send-button'),
              tooltip: strings.send,
              onPressed: () => _send(ref),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _send(WidgetRef ref) {
    final value = controller.text;
    if (value.trim().isEmpty) return;
    ref.read(messengerDemoProvider.notifier).sendText(conversationId, value);
    controller.clear();
  }
}

void _showLocalOnly(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
