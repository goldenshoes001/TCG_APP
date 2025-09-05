import 'package:flutter/material.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/sizing.dart';

class Barwidget extends StatefulWidget {
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
  State<Barwidget> createState() => _BarwidgetState();
}

class _BarwidgetState extends State<Barwidget> {
  // `mode` ist nicht mehr notwendig.
  bool? mode;

  // Der Ladevorgang wird beibehalten, um den Zustand der App zu speichern.
  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final loadedMode = await SaveData().loadBool("darkMode");
    setState(() {
      // isDarkMode wird hier gesetzt, aber das Icon wird direkt
      // über den Theme-Kontext gesteuert.
      mode = loadedMode;
    });
  }

  Future<void> saveThemeMode(bool newValue) async {
    await SaveData().saveBool("darkMode", newValue);
  }

  @override
  Widget build(BuildContext context) {
    // Der Code mit `mode == null` ist ebenfalls nicht mehr notwendig,
    // da wir den `context` direkt nutzen.

    // Rufe die Helligkeit des aktuellen Themes ab.
    final currentBrightness = Theme.of(context).brightness;
    final isDarkMode = currentBrightness == Brightness.dark;

    return AppBar(
      centerTitle: false,
      actions: [
        IconButton(
          // Basierend auf der Helligkeit des Themes das Icon wählen
          icon: isDarkMode
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            // Beim Klick den Theme-Modus umschalten und speichern.
            final newMode = !isDarkMode;
            widget.onThemeChanged(newMode);
            saveThemeMode(newMode);
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
