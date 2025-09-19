import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

import 'package:tcg_app/class/home.dart';
import 'package:tcg_app/class/search.dart';
import 'package:tcg_app/class/login.dart';
import 'package:tcg_app/class/meta.dart';

// Füge die Firebase-Imports hinzu
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Stellt sicher, dass das Flutter-Binding initialisiert ist
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiert Firebase mit den plattformspezifischen Optionen
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialisiert die Speicherung
  await SaveData.initPreferences();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SaveData data = SaveData();
  bool? isDarkMode;
  String name = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedMode = await data.loadBool("darkMode");
    setState(() {
      isDarkMode = loadedMode;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleDarkMode(bool newValue) {
    setState(() {
      isDarkMode = newValue;
    });
    data.saveBool("darkMode", newValue);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: isDarkMode == null
          ? ThemeMode.system
          : (isDarkMode! ? ThemeMode.dark : ThemeMode.light),
      home: MainScreen(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onThemeChanged: _toggleDarkMode,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  const MainScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const Home(),
      const Search(),
      Profile(
        selectedIndex: selectedIndex,
        onItemTapped: onItemTapped,
        onThemeChanged: onThemeChanged,
      ),
      const Meta(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height / appbarSize,
        ),
        child: Barwidget(
          title: "Cardbase",
          titleFlow: MainAxisAlignment.start,
          onThemeChanged: onThemeChanged,
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Bottombar(
        currentIndex: selectedIndex,
        valueChanged: onItemTapped,
        navigationItems: iconList,
      ),
    );
  }
}
