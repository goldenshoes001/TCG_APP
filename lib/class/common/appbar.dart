import 'package:flutter/material.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/sizing.dart';

// Barwidget ist jetzt ein StatelessWidget
class Barwidget extends StatefulWidget {
  final MainAxisAlignment titleFlow;
  final String title;
  final Function(bool) onThemeChanged; // Die Callback-Funktion

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
  bool mode = false;

  @override
  void initState() {
    super.initState();

    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await getThemeMode();
    setState(() {}); // UI nach dem Laden aktualisieren
  }

  Future<void> getThemeMode() async {
    SaveData data = SaveData();
    bool? loadedMode = await data.loadBool("darkMode");
    mode = loadedMode ?? false;
  }

  Future<void> saveThemeMode() async {
    SaveData data = SaveData();

    data.saveBool("darkMode", mode);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      actions: [
        Icon(mode ? Icons.light_mode : Icons.dark_mode),
        Switch(
          value: mode,
          onChanged: (newValue) {
            setState(() {
              mode = newValue;
              saveThemeMode();
            });
            widget.onThemeChanged(newValue);
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
