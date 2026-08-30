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

    return GlassAppBar(
      leading: onBack == null
          ? null
          : GlassIconButton(
              tooltip: strings.back,
              onPressed: onBack,
              icon: Icons.arrow_back_ios_new_rounded,
            ),
      title: Row(
        children: <Widget>[
          GlassAvatar(
            label: conversation.title,
            imageUrl: conversation.avatarUrl,
            group: !isDirect,
            size: 42,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Icon(
                      isDirect ? Icons.lock_rounded : Icons.group_outlined,
                      size: 11,
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
              ],
            ),
          ),
        ],
      ),
      actions: isDirect && ChatNuCapabilities.current.oneToOneCalls
          ? <Widget>[
              GlassIconButton(
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
                icon: Icons.videocam_rounded,
              ),
              const SizedBox(width: 2),
              GlassIconButton(
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
                icon: Icons.call_rounded,
              ),
            ]
          : const <Widget>[],
    );
  }
}
