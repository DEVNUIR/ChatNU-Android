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
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: Row(
        children: <Widget>[
          _NavigationRail(destination: state.destination),
          if (state.destination == MessengerDestination.chats) ...<Widget>[
            SizedBox(
              width: windowClass == ChatNuWindowClass.desktop ? 370 : 310,
              child: ConversationListPane(
                onSelected: ref
                    .read(messengerDemoProvider.notifier)
                    .selectConversation,
              ),
            ),
            VerticalDivider(width: 1, color: palette.borderSubtle),
            Expanded(
              child: selectedId == null
                  ? _NoConversationSelected(loading: state.isLoading)
                  : ConversationPane(conversationId: selectedId!),
            ),
          ] else
            Expanded(child: _DestinationContent(state.destination)),
        ],
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
      return Scaffold(
        body: ConversationPane(
          conversationId: selectedId!,
          onBack: controller.clearConversationSelection,
        ),
      );
    }

    return Scaffold(
      body: switch (state.destination) {
        MessengerDestination.chats => ConversationListPane(
          onSelected: controller.selectConversation,
        ),
        MessengerDestination.contacts || MessengerDestination.settings =>
          _DestinationContent(state.destination),
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
    final palette = context.chatNu;
    return Container(
      width: 82,
      color: palette.backgroundPrimary,
      padding: const EdgeInsets.symmetric(vertical: ChatNuSpacing.md),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const ChatNuMark(size: 36),
            const SizedBox(height: ChatNuSpacing.lg),
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
              onPressed: () =>
                  _setDestination(ref, MessengerDestination.contacts),
            ),
            const Spacer(),
            _RailButton(
              icon: Icons.settings_outlined,
              label: strings.settings,
              selected: destination == MessengerDestination.settings,
              onPressed: () =>
                  _setDestination(ref, MessengerDestination.settings),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: ChatNuSpacing.xs),
      child: GlassIconButton(
        icon: icon,
        tooltip: label,
        selected: selected,
        size: 52,
        onPressed: onPressed,
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
    return NavigationBar(
      selectedIndex: destination.index,
      onDestinationSelected: (index) {
        ref
            .read(messengerDemoProvider.notifier)
            .setDestination(MessengerDestination.values[index]);
      },
      destinations: <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: strings.chats,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded),
          label: strings.contacts,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          label: strings.settings,
        ),
      ],
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
    return Center(
      child: loading
          ? const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              strings.noConversation,
              style: Theme.of(context).textTheme.bodyLarge,
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
