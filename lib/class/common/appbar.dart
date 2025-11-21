import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Barwidget extends ConsumerWidget {
  final MainAxisAlignment titleFlow;
  final String title;
  final Function(bool) onThemeChanged;

  const Barwidget({
    super.key,
    this.titleFlow = MainAxisAlignment.center,
    this.title = "",
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;

    return AppBar(
      centerTitle: false,
      actions: [
        IconButton(
          icon: isDarkMode
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            final newMode = !isDarkMode;
            onThemeChanged(newMode);
            // Update über Provider
            ref.read(darkModeProvider.notifier).toggleDarkMode(newMode);
          },
        ),
      ],
      title: Row(
        mainAxisAlignment: titleFlow,
        children: [
          ClipRRect(
            child: Image.asset(
              'assets/icon/appicon.png',
              height: 15,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * widthSizedBoxAppBar,
          ),
          Text(title),
        ],
      ),
    );
  }
}
