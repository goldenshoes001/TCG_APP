import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/providers/app_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tcg_app/providers/language_provider.dart';

class Barwidget extends ConsumerStatefulWidget {
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
  ConsumerState<Barwidget> createState() => _BarwidgetState();
}

class _BarwidgetState extends ConsumerState<Barwidget> {
  Future<void> _handleLanguageSwitch() async {
    final newLocale = context.locale.languageCode == 'en'
        ? const Locale('de')
        : const Locale('en');

    // ✅ WICHTIG: Erst Provider updaten (synchron, während Widget noch mounted ist)
    ref.read(languageNotifierProvider.notifier).setLanguage(newLocale);

    // ✅ Dann setLocale aufrufen (async - löst Rebuild aus)
    await context.setLocale(newLocale);

    // ✅ Prüfe ob Widget noch mounted ist
    if (!mounted) return;

    // ✅ Zeige SnackBar nur wenn noch mounted
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLocale.languageCode == 'de'
                ? 'Sprache zu Deutsch gewechselt'
                : 'Language switched to English',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;

    return AppBar(
      centerTitle: false,
      actions: [
        // 🌍 Language Switch Button
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: context.locale.languageCode == 'en'
              ? 'Switch to German'
              : 'Zu Englisch wechseln',
          onPressed: _handleLanguageSwitch,
        ),
        // 🌓 Dark Mode Button
        IconButton(
          icon: isDarkMode
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            final newMode = !isDarkMode;
            widget.onThemeChanged(newMode);
            ref.read(darkModeProvider.notifier).toggleDarkMode(newMode);
          },
        ),
      ],
      title: Row(
        mainAxisAlignment: widget.titleFlow,
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
          Text(widget.title),
        ],
      ),
    );
  }
}
