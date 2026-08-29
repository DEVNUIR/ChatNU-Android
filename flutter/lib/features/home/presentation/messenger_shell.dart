import 'dart:async';
import 'dart:ui';

import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/responsive/chatnu_breakpoints.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/contacts/presentation/contacts_pane.dart';
import 'package:chatnu/features/contacts/presentation/new_chat_sheet.dart';
import 'package:chatnu/features/conversations/presentation/conversation_list_pane.dart';
import 'package:chatnu/features/home/application/demo_messenger_controller.dart';
import 'package:chatnu/features/messages/presentation/conversation_pane.dart';
import 'package:chatnu/features/settings/presentation/settings_pane.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessengerShell extends ConsumerWidget {
  const MessengerShell({super.key, this.initialConversationId});

  final String? initialConversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerDemoProvider);
    final windowClass = ChatNuBreakpoints.of(context);
    final selectedId =
        initialConversationId ??
        state.selectedConversationId ??
        (windowClass == ChatNuWindowClass.phone
            ? null
            : state.conversations.firstOrNull?.id);

    if (windowClass == ChatNuWindowClass.phone) {
      return _PhoneShell(state: state, selectedId: selectedId);
    }
    return _WideShell(
      state: state,
      selectedId: selectedId,
      windowClass: windowClass,
    );
  }
}

class _WideShell extends ConsumerWidget {
  const _WideShell({
    required this.state,
    required this.selectedId,
    required this.windowClass,
  });

  final MessengerDemoState state;
  final String? selectedId;
  final ChatNuWindowClass windowClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.chatNu;
    final listWidth = windowClass == ChatNuWindowClass.desktop
        ? ChatNuSizing.conversationListDesktop
        : ChatNuSizing.conversationListTablet;
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            _DesktopNavigation(destination: state.destination),
            if (state.destination == MessengerDestination.chats) ...<Widget>[
              Container(
                width: listWidth,
                margin: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: palette.backgroundSecondary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ConversationListPane(
                  onSelected: ref
                      .read(messengerDemoProvider.notifier)
                      .selectConversation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.fromSTEB(0, 12, 12, 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: palette.backgroundSecondary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: selectedId == null
                        ? _NoConversationSelected(
                            key: const ValueKey('empty-conversation'),
                            loading: state.isLoading,
                          )
                        : ConversationPane(
                            key: ValueKey('conversation-$selectedId'),
                            conversationId: selectedId!,
                          ),
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: palette.backgroundSecondary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: KeyedSubtree(
                      key: ValueKey(state.destination),
                      child: _DestinationContent(state.destination),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhoneShell extends ConsumerWidget {
  const _PhoneShell({required this.state, required this.selectedId});

  final MessengerDemoState state;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(messengerDemoProvider.notifier);
    final palette = context.chatNu;
    final inConversation =
        state.destination == MessengerDestination.chats && selectedId != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320);

    final content = inConversation
        ? ConversationPane(
            key: ValueKey('phone-conversation-$selectedId'),
            conversationId: selectedId!,
            onBack: controller.clearConversationSelection,
          )
        : switch (state.destination) {
            MessengerDestination.chats => ConversationListPane(
              key: const ValueKey('phone-chats'),
              onSelected: controller.selectConversation,
            ),
            MessengerDestination.contacts || MessengerDestination.settings =>
              KeyedSubtree(
                key: ValueKey('phone-${state.destination.name}'),
                child: _DestinationContent(state.destination),
              ),
          };

    return Scaffold(
      backgroundColor: palette.backgroundSecondary,
      body: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.025, 0.015),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: content,
      ),
      bottomNavigationBar: AnimatedSwitcher(
        duration: duration,
        child: inConversation
            ? const SizedBox.shrink(key: ValueKey('nav-hidden'))
            : _ReferenceBottomBar(
                key: const ValueKey('nav-visible'),
                destination: state.destination,
              ),
      ),
    );
  }
}

class _ReferenceBottomBar extends ConsumerWidget {
  const _ReferenceBottomBar({required this.destination, super.key});

  final MessengerDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.chatNu;
    final strings = ChatNuStrings.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SafeArea(
          top: false,
          child: Container(
            height: 72,
            padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 8),
            decoration: BoxDecoration(
              color: palette.backgroundElevated.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: palette.borderSubtle)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                  color: Colors.black.withValues(alpha: 0.045),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _BottomIcon(
                    icon: destination == MessengerDestination.chats
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    label: strings.chats,
                    selected: destination == MessengerDestination.chats,
                    onTap: () =>
                        _setDestination(ref, MessengerDestination.chats),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: FilledButton.icon(
                      key: const Key('new-chat-bottom-button'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(158, 48),
                        elevation: 0,
                        backgroundColor: palette.textPrimary,
                        foregroundColor: palette.backgroundElevated,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      onPressed: () => unawaited(showNewChatSheet(context)),
                      icon: const Icon(Icons.edit_rounded, size: 19),
                      label: Text(strings.newChat),
                    ),
                  ),
                ),
                Expanded(
                  child: _BottomIcon(
                    icon: destination == MessengerDestination.settings
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    label: strings.settings,
                    selected: destination == MessengerDestination.settings,
                    onTap: () =>
                        _setDestination(ref, MessengerDestination.settings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? palette.glassMedium.withValues(alpha: 0.72)
              : Colors.transparent,
        ),
        child: IconButton(
          onPressed: onTap,
          color: selected ? palette.textPrimary : palette.textMuted,
          icon: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: const Duration(milliseconds: 180),
            child: Icon(icon, size: 25),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigation extends ConsumerWidget {
  const _DesktopNavigation({required this.destination});

  final MessengerDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return SizedBox(
      width: 88,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 12, 10, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.backgroundElevated.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 14),
                  const ChatNuMark(size: 36),
                  const SizedBox(height: 24),
                  _DesktopNavButton(
                    icon: Icons.chat_bubble_rounded,
                    label: strings.chats,
                    selected: destination == MessengerDestination.chats,
                    onPressed: () =>
                        _setDestination(ref, MessengerDestination.chats),
                  ),
                  _DesktopNavButton(
                    icon: Icons.people_alt_outlined,
                    label: strings.contacts,
                    selected: destination == MessengerDestination.contacts,
                    onPressed: () =>
                        _setDestination(ref, MessengerDestination.contacts),
                  ),
                  const Spacer(),
                  _DesktopNavButton(
                    icon: Icons.tune_rounded,
                    label: strings.settings,
                    selected: destination == MessengerDestination.settings,
                    onPressed: () =>
                        _setDestination(ref, MessengerDestination.settings),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          backgroundColor: selected
              ? palette.glassMedium.withValues(alpha: 0.78)
              : Colors.transparent,
          foregroundColor: selected ? palette.textPrimary : palette.textMuted,
        ),
        icon: AnimatedScale(
          scale: selected ? 1.08 : 1,
          duration: const Duration(milliseconds: 180),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _DestinationContent extends StatelessWidget {
  const _DestinationContent(this.destination);

  final MessengerDestination destination;

  @override
  Widget build(BuildContext context) => switch (destination) {
    MessengerDestination.contacts => const ContactsPane(),
    MessengerDestination.settings => const SettingsPane(),
    MessengerDestination.chats => const SizedBox.shrink(),
  };
}

class _NoConversationSelected extends StatelessWidget {
  const _NoConversationSelected({required this.loading, super.key});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Center(
      child: loading
          ? const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: palette.textMuted,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  strings.noConversation,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
    );
  }
}

void _setDestination(WidgetRef ref, MessengerDestination destination) {
  ref.read(messengerDemoProvider.notifier).setDestination(destination);
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
