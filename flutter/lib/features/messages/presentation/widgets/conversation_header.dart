import 'dart:async';

import 'package:chatnu/core/di/app_providers.dart';
import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
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
    final actions = <Widget>[];
    if (isDirect && ChatNuCapabilities.current.oneToOneCalls) {
      actions.addAll(<Widget>[
        GlassIconButton(
          icon: Icons.call_outlined,
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
        ),
        GlassIconButton(
          icon: Icons.videocam_outlined,
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
        ),
      ]);
    }

    return GlassAppBar(
      leading: onBack == null
          ? null
          : GlassIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: strings.back,
              onPressed: onBack,
            ),
      title: Row(
        children: <Widget>[
          GlassAvatar(
            label: conversation.title,
            imageUrl: conversation.avatarUrl,
            group: !isDirect,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(start: 50),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isDirect ? Icons.lock_outline_rounded : Icons.group_outlined,
              size: 13,
              color: palette.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isDirect
                    ? strings.encrypted
                    : strings.members(conversation.members.length),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      actions: actions,
    );
  }
}
