import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Barwidget extends ConsumerWidget {
  final String title;
  final Function(bool) onThemeChanged;

  const Barwidget({super.key, this.title = "", required this.onThemeChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;

    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          child: Image.asset('assets/icon/appicon.png', height: 30),
        ),
      ),
      title: Text(title),
      actions: [
        IconButton(
          icon: isDarkMode
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            final newMode = !isDarkMode;
            onThemeChanged(newMode);
            ref.read(darkModeProvider.notifier).toggleDarkMode(newMode);
          },
        ),
      ],
    );
  }
}
