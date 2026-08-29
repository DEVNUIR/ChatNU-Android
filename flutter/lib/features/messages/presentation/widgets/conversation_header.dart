import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/product/chatnu_capabilities.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/features/calls/application/call_controller.dart';
import 'package:chatnu/features/conversations/domain/conversation.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationHeader extends ConsumerWidget {
  const ConversationHeader({
    required this.conversation,
    super.key,
    this.onBack,
  });

  final ChatNuConversation conversation;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final isDirect = conversation.kind == ConversationKind.direct;
    final currentUser = ref.watch(messengerDemoProvider).currentUser;
    final demo = ref.watch(appModeProvider) == ChatNuAppMode.demo;

    return Container(
      height: 70,
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: palette.backgroundElevated,
        border: Border(bottom: BorderSide(color: palette.borderSubtle)),
      ),
      child: Row(
        children: <Widget>[
          if (onBack != null)
            IconButton(
              tooltip: strings.back,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            ),
          _HeaderAvatar(
            label: conversation.title,
            imageUrl: conversation.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  isDirect
                      ? strings.encrypted
                      : strings.members(conversation.members.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isDirect && ChatNuCapabilities.current.oneToOneCalls) ...<Widget>[
            IconButton(
              tooltip: strings.videoCall,
              onPressed: demo
                  ? null
                  : () => unawaited(
                      ref
                          .read(callControllerProvider.notifier)
                          .startCall(
                            conversation: conversation,
                            currentUserId: currentUser.id,
                            video: true,
                          ),
                    ),
              icon: const Icon(Icons.videocam_outlined, size: 23),
            ),
            IconButton(
              tooltip: strings.voiceCall,
              onPressed: demo
                  ? null
                  : () => unawaited(
                      ref
                          .read(callControllerProvider.notifier)
                          .startCall(
                            conversation: conversation,
                            currentUserId: currentUser.id,
                            video: false,
                          ),
                    ),
              icon: const Icon(Icons.call_outlined, size: 22),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final url = imageUrl?.trim();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.glassMedium,
        image: url == null || url.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(
              label.isEmpty ? '?' : label.characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            )
          : null,
    );
  }
}
