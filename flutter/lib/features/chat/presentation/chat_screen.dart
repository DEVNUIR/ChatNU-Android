import 'package:chatnu/app/routing/app_router.dart';
import 'package:chatnu/core/responsive/chatnu_breakpoints.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/chat/application/chat_demo_controller.dart';
import 'package:chatnu/features/chat/presentation/chat_composer.dart';
import 'package:chatnu/features/chat/presentation/chat_messages.dart';
import 'package:chatnu/features/chat/presentation/chat_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _sidebarCollapsed = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _newChat() {
    ref.read(chatDemoControllerProvider.notifier).newChat();
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: ChatNuMotion.component,
        curve: ChatNuMotion.standard,
      );
    });
  }

  void _showSearchHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search is route-ready; indexing arrives with the backend migration.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAttachmentHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachment UI is ready. Encrypted transfer stays disabled until API integration.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final chatState = ref.watch(chatDemoControllerProvider);
    return Scaffold(
      backgroundColor: palette.backgroundPrimary,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newChat,
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): _showSearchHint,
          SingleActivator(LogicalKeyboardKey.comma, control: true):
              () => context.go(ChatNuRoutes.settings),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final windowClass = ChatNuBreakpoints.fromWidth(constraints.maxWidth);
              final showSidebar = windowClass != ChatNuWindowClass.phone;
              final sidebarCollapsed = windowClass == ChatNuWindowClass.tablet || _sidebarCollapsed;
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const _ChatBackground(),
                  SafeArea(
                    child: Row(
                      children: <Widget>[
                        if (showSidebar)
                          ChatSidebar(
                            collapsed: sidebarCollapsed,
                            onToggle: () {
                              if (windowClass == ChatNuWindowClass.desktop) {
                                setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                              }
                            },
                            onNewChat: _newChat,
                            onRoute: context.go,
                          ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              showSidebar ? ChatNuSpacing.sm : ChatNuSpacing.md,
                              ChatNuSpacing.sm,
                              ChatNuSpacing.md,
                              ChatNuSpacing.sm,
                            ),
                            child: Column(
                              children: <Widget>[
                                ChatTopBar(
                                  model: chatState.selectedModel,
                                  showMenu: !showSidebar,
                                  onMenuPressed: () => showMobileNavigation(
                                    context,
                                    onNewChat: _newChat,
                                    onRoute: context.go,
                                  ),
                                  onModelPressed: () => showModelSelector(context),
                                ),
                                const SizedBox(height: ChatNuSpacing.xs),
                                Expanded(
                                  child: Stack(
                                    children: <Widget>[
                                      Positioned.fill(
                                        child: ChatMessageList(
                                          messages: chatState.messages,
                                          modelName: chatState.selectedModel.name,
                                          controller: _scrollController,
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: ChatNuSpacing.xs,
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: ChatNuBreakpoints.conversationMaxWidth,
                                            ),
                                            child: ChatComposer(
                                              onSent: _scrollToLatest,
                                              onAttachmentPressed: _showAttachmentHint,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatBackground extends StatelessWidget {
  const _ChatBackground();

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.backgroundPrimary,
                  Color.alphaBlend(
                    palette.accentSecondary.withValues(alpha: 0.035),
                    palette.backgroundPrimary,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -180,
            right: -120,
            child: _AmbientOrb(
              size: 430,
              color: palette.accentPrimary.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            bottom: -220,
            left: -170,
            child: _AmbientOrb(
              size: 500,
              color: palette.accentSecondary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: <Color>[color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
