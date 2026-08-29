import 'dart:async';
import 'dart:ui';

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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: palette.backgroundElevated.withValues(alpha: 0.78),
            border: Border(bottom: BorderSide(color: palette.borderSubtle)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.035),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              if (onBack != null)
                _HeaderAction(
                  tooltip: strings.back,
                  onPressed: onBack,
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconSize: 18,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Icon(
                          isDirect
                              ? Icons.lock_rounded
                              : Icons.group_outlined,
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
              if (isDirect && ChatNuCapabilities.current.oneToOneCalls) ...<Widget>[
                _HeaderAction(
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
                _HeaderAction(
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.iconSize = 21,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(42, 42),
        backgroundColor: palette.backgroundElevated.withValues(alpha: 0.54),
        foregroundColor: palette.textPrimary,
        side: BorderSide(color: palette.borderSubtle),
      ),
      icon: Icon(icon, size: iconSize),
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.glassMedium,
        border: Border.all(color: palette.borderHighlight),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 12,
            color: palette.accent.withValues(alpha: 0.1),
          ),
        ],
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
