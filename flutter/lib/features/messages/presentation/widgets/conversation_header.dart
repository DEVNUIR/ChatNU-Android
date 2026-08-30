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
    this.searchOpen = false,
    this.searchController,
    this.searchFocusNode,
    this.searchResultLabel,
    this.onSearchChanged,
    this.onSearchToggle,
    this.onPreviousSearchResult,
    this.onNextSearchResult,
  });

  final ChatNuConversation conversation;
  final VoidCallback? onBack;
  final bool searchOpen;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final String? searchResultLabel;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchToggle;
  final VoidCallback? onPreviousSearchResult;
  final VoidCallback? onNextSearchResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    final isDirect = conversation.kind == ConversationKind.direct;
    final currentUser = ref.watch(messengerDemoProvider).currentUser;
    final demo = ref.watch(appModeProvider) == ChatNuAppMode.demo;
    final inSearchMode = searchOpen && searchController != null;

    return GlassAppBar(
      leading: onBack == null
          ? null
          : GlassIconButton(
              tooltip: strings.back,
              onPressed: onBack,
              icon: Icons.arrow_back_ios_new_rounded,
            ),
      title: inSearchMode
          ? TextField(
              key: const Key('conversation-search-field'),
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onSearchChanged,
              onSubmitted: (_) => onPreviousSearchResult?.call(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.searchInChat,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            )
          : Row(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
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
                                  : strings.members(
                                      conversation.members.length,
                                    ),
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
      actions: inSearchMode
          ? <Widget>[
              if (searchResultLabel != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, end: 2),
                  child: Center(
                    child: Text(
                      searchResultLabel!,
                      key: const Key('conversation-search-result-label'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              GlassIconButton(
                key: const Key('conversation-search-previous'),
                tooltip: strings.previousSearchResult,
                onPressed: onPreviousSearchResult,
                icon: Icons.keyboard_arrow_up_rounded,
              ),
              GlassIconButton(
                key: const Key('conversation-search-next'),
                tooltip: strings.nextSearchResult,
                onPressed: onNextSearchResult,
                icon: Icons.keyboard_arrow_down_rounded,
              ),
              GlassIconButton(
                key: const Key('conversation-search-close'),
                tooltip: strings.closeSearch,
                onPressed: onSearchToggle,
                icon: Icons.close_rounded,
              ),
            ]
          : <Widget>[
              if (isDirect &&
                  ChatNuCapabilities.current.oneToOneCalls) ...<Widget>[
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
              ],
              if (onSearchToggle != null) ...<Widget>[
                const SizedBox(width: 2),
                GlassIconButton(
                  key: const Key('conversation-search-button'),
                  tooltip: strings.searchInChat,
                  onPressed: onSearchToggle,
                  icon: Icons.search_rounded,
                ),
              ],
            ],
    );
  }
}
