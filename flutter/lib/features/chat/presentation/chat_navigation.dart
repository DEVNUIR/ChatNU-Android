import 'dart:async';

import 'package:chatnu/app/routing/app_router.dart';
import 'package:chatnu/core/glass/glass_surface.dart';
import 'package:chatnu/core/responsive/chatnu_breakpoints.dart';
import 'package:chatnu/core/theme/chatnu_theme.dart';
import 'package:chatnu/core/theme/chatnu_tokens.dart';
import 'package:chatnu/features/chat/application/chat_demo_controller.dart';
import 'package:chatnu/features/chat/domain/chat_models.dart';
import 'package:chatnu/shared/widgets/chatnu_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    required this.model,
    required this.showMenu,
    required this.onMenuPressed,
    required this.onModelPressed,
    super.key,
  });

  final AiModelOption model;
  final bool showMenu;
  final VoidCallback onMenuPressed;
  final VoidCallback onModelPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return GlassSurface(
      variant: GlassVariant.weak,
      borderRadius: ChatNuRadii.lg,
      enableBlur: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: <Widget>[
          if (showMenu) ...<Widget>[
            GlassIconButton(
              icon: Icons.menu_rounded,
              tooltip: 'Navigation',
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: ChatNuSpacing.xs),
          ],
          const ChatNuMark(size: 34),
          const SizedBox(width: ChatNuSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'New conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Local UI prototype · no network',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ChatNuSpacing.sm),
          _ModelButton(model: model, onPressed: onModelPressed),
        ],
      ),
    );
  }
}

class _ModelButton extends StatefulWidget {
  const _ModelButton({required this.model, required this.onPressed});

  final AiModelOption model;
  final VoidCallback onPressed;

  @override
  State<_ModelButton> createState() => _ModelButtonState();
}

class _ModelButtonState extends State<_ModelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: ChatNuMotion.micro,
          curve: ChatNuMotion.standard,
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? palette.glassMedium : palette.glassWeak,
            borderRadius: BorderRadius.circular(ChatNuRadii.md),
            border: Border.all(
              color: _hovered ? palette.borderHighlight : palette.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, size: 16, color: palette.accentPrimary),
              const SizedBox(width: 7),
              Text(widget.model.name, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    required this.collapsed,
    required this.onToggle,
    required this.onNewChat,
    required this.onRoute,
    super.key,
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  final ValueChanged<String> onRoute;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return AnimatedContainer(
      duration: ChatNuMotion.component,
      curve: ChatNuMotion.emphasized,
      width: collapsed ? 78 : 278,
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: GlassSurface(
        variant: GlassVariant.strong,
        borderRadius: ChatNuRadii.lg,
        enableBlur: true,
        padding: const EdgeInsets.all(ChatNuSpacing.sm),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: <Widget>[
                const ChatNuMark(size: 38),
                if (!collapsed) ...<Widget>[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('ChatNU', style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ],
            ),
            const SizedBox(height: ChatNuSpacing.lg),
            _SidebarItem(
              icon: Icons.add_rounded,
              label: 'New chat',
              collapsed: collapsed,
              emphasized: true,
              onTap: onNewChat,
            ),
            _SidebarItem(
              icon: Icons.search_rounded,
              label: 'Search',
              collapsed: collapsed,
              onTap: () => onRoute(ChatNuRoutes.history),
            ),
            const SizedBox(height: ChatNuSpacing.md),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'RECENT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            if (!collapsed) ...<Widget>[
              const _RecentConversation(title: 'Flutter architecture', subtitle: '2m'),
              const _RecentConversation(title: 'Landing page review', subtitle: '1h'),
              const _RecentConversation(title: 'یادگیری انگلیسی', subtitle: '3h'),
            ],
            const Spacer(),
            _SidebarItem(
              icon: Icons.hub_outlined,
              label: 'Models',
              collapsed: collapsed,
              onTap: () => onRoute(ChatNuRoutes.models),
            ),
            _SidebarItem(
              icon: Icons.tune_rounded,
              label: 'Settings',
              collapsed: collapsed,
              onTap: () => onRoute(ChatNuRoutes.settings),
            ),
            _SidebarItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              collapsed: collapsed,
              onTap: () => onRoute(ChatNuRoutes.profile),
            ),
            const SizedBox(height: ChatNuSpacing.xs),
            Divider(color: palette.borderSubtle),
            _SidebarItem(
              icon: collapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded,
              label: 'Collapse',
              collapsed: collapsed,
              onTap: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    final active = _hovered || widget.emphasized;
    return Tooltip(
      message: widget.collapsed ? widget.label : '',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: ChatNuMotion.micro,
            margin: const EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 10 : 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ChatNuRadii.md),
              color: active
                  ? widget.emphasized
                        ? palette.accentPrimary.withValues(alpha: 0.14)
                        : palette.glassMedium
                  : Colors.transparent,
              border: Border.all(
                color: active ? palette.borderSubtle : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.emphasized ? palette.accentPrimary : palette.textSecondary,
                ),
                if (!widget.collapsed) ...<Widget>[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentConversation extends StatelessWidget {
  const _RecentConversation({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

void showModelSelector(BuildContext context) {
  final isPhone = ChatNuBreakpoints.of(context) == ChatNuWindowClass.phone;
  if (isPhone) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.48),
        builder: (_) => const Padding(
          padding: EdgeInsets.all(ChatNuSpacing.sm),
          child: _ModelPickerPanel(),
        ),
      ),
    );
  } else {
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        builder: (_) => const Center(
          child: Padding(
            padding: EdgeInsets.all(ChatNuSpacing.lg),
            child: SizedBox(width: 430, child: _ModelPickerPanel()),
          ),
        ),
      ),
    );
  }
}

class _ModelPickerPanel extends ConsumerWidget {
  const _ModelPickerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chatDemoControllerProvider.select((value) => value.selectedModel));
    return Material(
      color: Colors.transparent,
      child: GlassSurface(
        variant: GlassVariant.strong,
        borderRadius: ChatNuRadii.xl,
        enableBlur: true,
        padding: const EdgeInsets.all(ChatNuSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Choose model', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Capability first. Technical details stay secondary.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: ChatNuSpacing.md),
            for (final model in chatNuDemoModels)
              _ModelRow(
                model: model,
                selected: selected.id == model.id,
                onTap: () {
                  ref.read(chatDemoControllerProvider.notifier).selectModel(model);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model, required this.selected, required this.onTap});

  final AiModelOption model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: ChatNuSpacing.xs),
        padding: const EdgeInsets.all(ChatNuSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? palette.accentPrimary.withValues(alpha: 0.12) : palette.glassWeak,
          borderRadius: BorderRadius.circular(ChatNuRadii.md),
          border: Border.all(
            color: selected ? palette.accentPrimary.withValues(alpha: 0.48) : palette.borderSubtle,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: palette.glassMedium,
                borderRadius: BorderRadius.circular(ChatNuRadii.sm),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: palette.accentPrimary),
            ),
            const SizedBox(width: ChatNuSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(model.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${model.capability} · ${model.speedLabel}${model.contextLabel == null ? '' : ' · ${model.contextLabel}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: palette.accentPrimary, size: 21),
          ],
        ),
      ),
    );
  }
}

void showMobileNavigation(
  BuildContext context, {
  required VoidCallback onNewChat,
  required ValueChanged<String> onRoute,
}) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(ChatNuSpacing.sm),
        child: Material(
          color: Colors.transparent,
          child: GlassSurface(
            variant: GlassVariant.strong,
            borderRadius: ChatNuRadii.xl,
            enableBlur: true,
            padding: const EdgeInsets.all(ChatNuSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const ChatNuMark(),
                    const SizedBox(width: 10),
                    Text('ChatNU', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    GlassIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: ChatNuSpacing.md),
                _MobileNavAction(
                  icon: Icons.add_rounded,
                  label: 'New chat',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onNewChat();
                  },
                ),
                for (final item in <({IconData icon, String label, String path})>[
                  (icon: Icons.history_rounded, label: 'History', path: ChatNuRoutes.history),
                  (icon: Icons.hub_outlined, label: 'Models', path: ChatNuRoutes.models),
                  (icon: Icons.tune_rounded, label: 'Settings', path: ChatNuRoutes.settings),
                  (icon: Icons.person_outline_rounded, label: 'Profile', path: ChatNuRoutes.profile),
                ])
                  _MobileNavAction(
                    icon: item.icon,
                    label: item.label,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onRoute(item.path);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MobileNavAction extends StatelessWidget {
  const _MobileNavAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.chatNu;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: <Widget>[
            Icon(icon, color: palette.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
