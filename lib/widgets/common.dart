// FixMate — small shared widgets used across pages

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: .075)
                : Colors.white.withValues(alpha: .58),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .14)
                  : Colors.white.withValues(alpha: .8),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class FixMateLogo extends StatelessWidget {
  final double size;

  const FixMateLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return Icon(
          Icons.handyman,
          size: size * .7,
          color: FixMateTheme.gold,
        );
      },
    );
  }
}


class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return TextButton(
      onPressed: state.toggleLanguage,
      child: Text(
        state.language == 'English'
            ? 'EN | FR'
            : 'FR | EN',
        style: const TextStyle(
          color: FixMateTheme.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;

    final isDark =
        state.themeMode == ThemeMode.dark;

    return IconButton(
      onPressed: state.toggleTheme,
      tooltip: isDark
          ? t('Light mode')
          : t('Dark mode'),
      icon: Icon(
        isDark
            ? Icons.light_mode
            : Icons.dark_mode,
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              GlassPanel(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(13),
                child: Icon(
                  icon,
                  color: FixMateTheme.gold,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(description),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FixMateAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<String> suggestions;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> actions;

  const FixMateAppBar({
    super.key,
    required this.title,
    this.suggestions = const [],
    this.onSearchChanged,
    this.actions = const [],
  });

  @override
  State<FixMateAppBar> createState() => _FixMateAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FixMateAppBarState extends State<FixMateAppBar> {
  bool searchOpen = false;
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggleSearch() {
    setState(() => searchOpen = !searchOpen);
    if (!searchOpen) {
      controller.clear();
      widget.onSearchChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.tr;
    final canSearch = widget.onSearchChanged != null;

    return AppBar(
      title: searchOpen && canSearch
          ? TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => widget.onSearchChanged
                  ?.call(normalizeSearch(value.trim())),
              decoration: InputDecoration(
                hintText: widget.suggestions.isEmpty
                    ? t('Search...')
                    : t(widget.suggestions.first),
                border: InputBorder.none,
                filled: false,
              ),
            )
          : Text(widget.title),
      actions: [
        ...widget.actions,
        if (canSearch)
          IconButton(
            onPressed: toggleSearch,
            icon: Icon(searchOpen ? Icons.close : Icons.search),
          ),
        const LanguageButton(),
        const ThemeButton(),
      ],
    );
  }
}

class CertifiedBadge extends StatelessWidget {
  const CertifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Certified',
      child: Icon(
        Icons.verified,
        color: Colors.blue,
        size: 23,
      ),
    );
  }
}
