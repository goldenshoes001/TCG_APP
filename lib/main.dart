import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SaveData data = SaveData();
  await data.initPreferences();
  bool? darkMode = await data.loadBool("darkMode");

  runApp(MainApp(data: data, darkMode: darkMode ?? true));
}

class MainApp extends StatefulWidget {
  final SaveData data;
  bool darkMode;

  MainApp({super.key, required this.data, required this.darkMode});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: widget.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        data: widget.data,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        darkMode: widget.darkMode,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final SaveData data;
  final int selectedIndex;
  final Function(int) onItemTapped;
  bool darkMode;

  MainScreen({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height / appbarSize,
        ),
        child: Barwidget(
          title: "Cardbase",
          titleFlow: MainAxisAlignment.start,
          darkMode: darkMode,
        ),
      ),
      body: widgetListe[selectedIndex],
      bottomNavigationBar: Bottombar(
        currentIndex: selectedIndex,
        valueChanged: onItemTapped,
        navigationItems: iconList,
      ),
    );
  }
}
