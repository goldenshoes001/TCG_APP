import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

// Importieren Sie die Seiten, die Sie in der Navigation verwenden
import 'package:tcg_app/class/home.dart';
import 'package:tcg_app/class/search.dart';
import 'package:tcg_app/class/profile.dart';
import 'package:tcg_app/class/meta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = SaveData();
  await data.initPreferences();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SaveData data = SaveData();
  bool isDarkMode = false;

  String name = "";
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // Methode, um die Daten asynchron zu laden
  Future<void> _loadData() async {
    final loadedMode = await data.loadBool("darkMode");
    setState(() {
      isDarkMode = loadedMode ?? false;
      _isLoading = false;
    });
  }

  // Callback-Methode für die Bottom-Navigation-Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Callback-Methode, die den Zustand von isDarkMode ändert
  void _toggleDarkMode(bool newValue) {
    setState(() {
      isDarkMode = newValue;
    });
    data.saveBool("darkMode", newValue);
  }

  @override
  Widget build(BuildContext context) {
    // Zeige einen Ladeindikator, während die Daten geladen werden
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        data: data,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onThemeChanged: _toggleDarkMode,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final SaveData data;
  final int selectedIndex;
  final Function(int) onItemTapped;

  final Function(bool) onThemeChanged;

  const MainScreen({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onItemTapped,

    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Die Liste der Widgets wird direkt in der build-Methode erstellt,
    // um Zugriff auf die Zustandsvariablen zu haben.
    final List<Widget> pages = [
      const Home(),
      const Search(),
      Profile(
        data: data,
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
