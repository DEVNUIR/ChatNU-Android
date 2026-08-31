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
    final transitionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ChatNuMotion.component;
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
                  showComposeAction: true,
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
                    duration: transitionDuration,
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
                    duration: transitionDuration,
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
    final strings = ChatNuStrings.of(context);
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
            MessengerDestination.contacts ||
            MessengerDestination.settings => KeyedSubtree(
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
          if (reduceMotion) return child;
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
      floatingActionButton: inConversation
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-chat-fab'),
              onPressed: () => unawaited(showNewChatSheet(context)),
              backgroundColor: palette.accentPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.edit_rounded, size: 19),
              label: Text(strings.newChat),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
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
                    key: const Key('phone-nav-chats'),
                    icon: destination == MessengerDestination.chats
                        ? Icons.chat_rounded
                        : Icons.chat_outlined,
                    label: strings.chats,
                    selected: destination == MessengerDestination.chats,
                    onTap: () =>
                        _setDestination(ref, MessengerDestination.chats),
                  ),
                ),
                Expanded(
                  child: _BottomIcon(
                    key: const Key('phone-nav-contacts'),
                    icon: destination == MessengerDestination.contacts
                        ? Icons.contacts_rounded
                        : Icons.contacts_outlined,
                    label: strings.contacts,
                    selected: destination == MessengerDestination.contacts,
                    onTap: () =>
                        _setDestination(ref, MessengerDestination.contacts),
                  ),
                ),
                Expanded(
                  child: _BottomIcon(
                    key: const Key('phone-nav-settings'),
                    icon: destination == MessengerDestination.settings
                        ? Icons.settings_rounded
                        : Icons.settings_outlined,
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
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ChatNuMotion.micro;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        constraints: const BoxConstraints(
          minHeight: ChatNuSizing.minTouchTarget,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? palette.accentPrimary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: duration,
                  child: Icon(
                    icon,
                    size: 23,
                    color: selected ? palette.accentPrimary : palette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? palette.accentPrimary : palette.textMuted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                    icon: Icons.chat_rounded,
                    label: strings.chats,
                    selected: destination == MessengerDestination.chats,
                    onPressed: () =>
                        _setDestination(ref, MessengerDestination.chats),
                  ),
                  _DesktopNavButton(
                    icon: Icons.contacts_outlined,
                    label: strings.contacts,
                    selected: destination == MessengerDestination.contacts,
                    onPressed: () =>
                        _setDestination(ref, MessengerDestination.contacts),
                  ),
                  const Spacer(),
                  _DesktopNavButton(
                    icon: Icons.settings_rounded,
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ChatNuMotion.micro;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        onTap: onPressed,
        excludeSemantics: true,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            backgroundColor: selected
                ? palette.accentPrimary.withValues(alpha: 0.12)
                : Colors.transparent,
            foregroundColor: selected ? palette.accentPrimary : palette.textMuted,
          ),
          icon: AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: duration,
            child: Icon(icon),
          ),
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
                  Icons.chat_outlined,
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
