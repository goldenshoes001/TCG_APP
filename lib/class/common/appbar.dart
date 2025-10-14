import 'package:flutter/material.dart';
import 'package:tcg_app/class/sharedPreference.dart';
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
  bool? mode;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final loadedMode = await SaveData().loadBool("darkMode");
    setState(() {
      mode = loadedMode;
    });
  }

  Future<void> saveThemeMode(bool newValue) async {
    await SaveData().saveBool("darkMode", newValue);
  }

  @override
  Widget build(BuildContext context) {
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
