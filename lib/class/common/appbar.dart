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
  // `mode` is now nullable. It will be `null` until the data is loaded.
  bool? mode;

  @override
  void initState() {
    super.initState();
    // Start the asynchronous loading process.
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final loadedMode = await SaveData().loadBool("darkMode");
    setState(() {
      // Update the state with the loaded value.
      mode = loadedMode ?? false;
    });
  }

  Future<void> saveThemeMode(bool newValue) async {
    await SaveData().saveBool("darkMode", newValue);
  }

  @override
  Widget build(BuildContext context) {
    // Check if the mode is still null (data is not yet loaded).
    if (mode == null) {
      return AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      );
    }

    return AppBar(
      centerTitle: false,
      actions: [
        IconButton(
          icon: mode!
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            setState(() {
              // Schalte den Wert von 'mode' um
              mode = !mode!;
            });
            // Rufe die Funktionen mit dem umgeschalteten Wert auf
            saveThemeMode(mode!);
            widget.onThemeChanged(mode!);
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
