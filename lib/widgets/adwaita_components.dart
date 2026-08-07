import 'package:flutter/material.dart';

import '../core/tokyo_palette.dart';

const appTransitionDuration = Duration(milliseconds: 180);

/// The short transition used by the application shell.
Duration appMotionDuration(BuildContext context) {
  final mediaQuery = MediaQuery.maybeOf(context);
  return mediaQuery?.disableAnimations ?? false
      ? Duration.zero
      : appTransitionDuration;
}

AnimationStyle appAnimationStyle(BuildContext context) {
  if (appMotionDuration(context) == Duration.zero) {
    return AnimationStyle.noAnimation;
  }
  return const AnimationStyle(
    duration: appTransitionDuration,
    reverseDuration: appTransitionDuration,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
}

Widget appPageTransition(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  if (appMotionDuration(context) == Duration.zero) return child;
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: child,
  );
}

Route<T> appPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: appTransitionDuration,
    reverseTransitionDuration: appTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        appPageTransition(context, animation, child),
  );
}

/// A small, responsive header bar shared by every application page.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({
    required this.title,
    this.actions = const [],
    this.showBack = false,
    super.key,
  });

  final String title;
  final List<AppHeaderAction> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Material(
      color: palette.headerBar,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (showBack)
                      BackButton(
                        key: const ValueKey('header_back_button'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).appBarTheme.titleTextStyle,
                      ),
                    ),
                    for (final action in actions)
                      _buildAction(context, action, compact),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    AppHeaderAction action,
    bool compact,
  ) {
    if (compact || !action.isPrimary) {
      return IconButton(
        key: action.key,
        tooltip: action.tooltip ?? action.label,
        icon: Icon(action.icon),
        onPressed: action.onPressed,
      );
    }
    final button = FilledButton.icon(
      key: action.key,
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: action.tooltip == null
          ? button
          : Tooltip(message: action.tooltip!, child: button),
    );
  }
}

class AppHeaderAction {
  const AppHeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.key,
    this.tooltip,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Key? key;
  final String? tooltip;
  final bool isPrimary;
}

/// An Adwaita-style status page used for empty and setup states.
class StatusPage extends StatelessWidget {
  const StatusPage({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: palette.textMuted),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: palette.text),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A bordered list surface that keeps rows aligned on wide and narrow views.
class BoxedList extends StatelessWidget {
  const BoxedList({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.border.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: palette.view,
            child: Column(children: children),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of related preferences on a shared boxed surface.
class PreferencesGroup extends StatelessWidget {
  const PreferencesGroup({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Semantics(
                container: true,
                excludeSemantics: true,
                header: true,
                label: title,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ),
            BoxedList(children: children),
          ],
        ),
      ),
    );
  }
}

/// A preference/action row with consistent focus, hover and disabled behavior.
class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      leading: leading,
      trailing: trailing,
      enabled: onTap != null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minVerticalPadding: 8,
    );
  }
}

class ComboOption<T> {
  const ComboOption({
    required this.value,
    required this.label,
    required this.description,
    this.swatch = const [],
  });

  final T value;
  final String label;
  final String description;
  final List<Color> swatch;
}

/// A compact preference row that opens its options in a keyboard-accessible
/// popover.
class ComboRow<T> extends StatefulWidget {
  const ComboRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<ComboOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  State<ComboRow<T>> createState() => _ComboRowState<T>();
}

class _ComboRowState<T> extends State<ComboRow<T>> {
  final _menuKey = GlobalKey<PopupMenuButtonState<T>>();

  @override
  Widget build(BuildContext context) {
    final selected = widget.options.firstWhere(
      (option) => option.value == widget.value,
    );
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => _menuKey.currentState?.showButtonMenu(),
      trailing: PopupMenuButton<T>(
        key: _menuKey,
        initialValue: widget.value,
        tooltip: widget.title,
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        popUpAnimationStyle: appAnimationStyle(context),
        onSelected: widget.onChanged,
        itemBuilder: (context) => [
          for (final option in widget.options)
            PopupMenuItem<T>(
              value: option.value,
              child: Row(
                children: [
                  if (option.swatch.isNotEmpty) ...[
                    _ColorSwatch(
                      colors: option.swatch,
                      semanticLabel: '${option.label} 配色色板',
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.label),
                        Text(
                          option.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (option.value == widget.value)
                    const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.label),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.colors, required this.semanticLabel});

  final List<Color> colors;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: 36,
          height: 18,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final color in colors)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppToastKind { success, error }

void showAppToast(
  BuildContext context,
  String message, {
  required AppToastKind kind,
}) {
  final palette = Theme.of(context).extension<TokyoPalette>()!;
  final (color, foreground, icon, duration) = switch (kind) {
    AppToastKind.success => (
      palette.success,
      palette.onSuccess,
      Icons.check_circle_outline,
      const Duration(seconds: 2),
    ),
    AppToastKind.error => (
      palette.destructive,
      palette.onDestructive,
      Icons.error_outline,
      const Duration(seconds: 4),
    ),
  };
  final animationStyle = appAnimationStyle(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
      snackBarAnimationStyle: animationStyle,
    );
}

Future<bool> showAppMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        animationStyle: appAnimationStyle(context),
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: destructive
                    ? TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          dialogContext,
                        ).extension<TokyoPalette>()!.destructive,
                      )
                    : null,
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ) ??
      false;
}
