import 'package:chatnu/core/glass/glass_components.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/localization/chatnu_strings.dart';
import 'package:chatnu/core/responsive/chatnu_breakpoints.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/contacts/presentation/contacts_pane.dart';
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
    return GlassScaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            _NavigationRail(destination: state.destination),
            if (state.destination == MessengerDestination.chats) ...<Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  0,
                  ChatNuSpacing.sm,
                  ChatNuSpacing.sm,
                  ChatNuSpacing.sm,
                ),
                child: SizedBox(
                  width: listWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ChatNuRadii.lg),
                    child: ConversationListPane(
                      onSelected: ref
                          .read(messengerDemoProvider.notifier)
                          .selectConversation,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: palette.borderSubtle),
              Expanded(
                child: selectedId == null
                    ? _NoConversationSelected(loading: state.isLoading)
                    : ConversationPane(conversationId: selectedId!),
              ),
            ] else
              Expanded(child: _DestinationContent(state.destination)),
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
    if (state.destination == MessengerDestination.chats && selectedId != null) {
      return GlassScaffold(
        body: ConversationPane(
          conversationId: selectedId!,
          onBack: controller.clearConversationSelection,
        ),
      );
    }

    return GlassScaffold(
      body: switch (state.destination) {
        MessengerDestination.chats => ConversationListPane(
          onSelected: controller.selectConversation,
        ),
        MessengerDestination.contacts ||
        MessengerDestination.settings => _DestinationContent(state.destination),
      },
      bottomNavigationBar: _PhoneNavigation(destination: state.destination),
    );
  }
}

class _NavigationRail extends ConsumerWidget {
  const _NavigationRail({required this.destination});

  final MessengerDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    return GlassNavigationRail(
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: ChatNuSpacing.xs),
            child: ChatNuMark(size: 38),
          ),
          const SizedBox(height: ChatNuSpacing.md),
          _RailButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: strings.chats,
            selected: destination == MessengerDestination.chats,
            onPressed: () => _setDestination(ref, MessengerDestination.chats),
          ),
          _RailButton(
            icon: Icons.people_outline_rounded,
            label: strings.contacts,
            selected: destination == MessengerDestination.contacts,
            onPressed: () => _setDestination(ref, MessengerDestination.contacts),
          ),
          const Spacer(),
          _RailButton(
            icon: Icons.settings_outlined,
            label: strings.settings,
            selected: destination == MessengerDestination.settings,
            onPressed: () => _setDestination(ref, MessengerDestination.settings),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
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
      padding: const EdgeInsets.only(bottom: ChatNuSpacing.xs),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (selected)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: palette.accentPrimary.withValues(alpha: 0.22),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              GlassIconButton(
                icon: icon,
                tooltip: label,
                selected: selected,
                size: 52,
                onPressed: onPressed,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? palette.textPrimary : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneNavigation extends ConsumerWidget {
  const _PhoneNavigation({required this.destination});

  final MessengerDestination destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ChatNuStrings.of(context);
    return GlassBottomBar(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PhoneNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: strings.chats,
              selected: destination == MessengerDestination.chats,
              onTap: () => _setDestination(ref, MessengerDestination.chats),
            ),
          ),
          Expanded(
            child: _PhoneNavItem(
              icon: Icons.people_outline_rounded,
              label: strings.contacts,
              selected: destination == MessengerDestination.contacts,
              onTap: () => _setDestination(ref, MessengerDestination.contacts),
            ),
          ),
          Expanded(
            child: _PhoneNavItem(
              icon: Icons.settings_outlined,
              label: strings.settings,
              selected: destination == MessengerDestination.settings,
              onTap: () => _setDestination(ref, MessengerDestination.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneNavItem extends StatelessWidget {
  const _PhoneNavItem({
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
      child: InkWell(
        borderRadius: BorderRadius.circular(ChatNuRadii.md),
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : ChatNuMotion.micro,
          constraints: const BoxConstraints(
            minHeight: ChatNuSizing.minTouchTarget,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? palette.glassMedium : Colors.transparent,
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            border: Border.all(
              color: selected ? palette.borderHighlight : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 21,
                color: selected ? palette.accentPrimary : palette.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? palette.textPrimary : palette.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
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
  const _NoConversationSelected({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final strings = ChatNuStrings.of(context);
    final palette = context.chatNu;
    return Center(
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : ChatNuMotion.component,
        child: loading
            ? const SizedBox.square(
                key: ValueKey<String>('loading'),
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : GlassCard(
                key: const ValueKey<String>('empty'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline_rounded,
                      color: palette.accentPrimary,
                      size: 28,
                    ),
                    const SizedBox(height: ChatNuSpacing.sm),
                    Text(
                      strings.noConversation,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
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
