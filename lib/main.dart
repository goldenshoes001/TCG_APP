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
import 'package:tcg_app/class/common/user_profile_side.dart';
import 'package:tcg_app/class/meta.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

      // Der StreamBuilder entscheidet direkt, welche Hauptseite angezeigt wird
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Benutzer ist angemeldet, zeige den Hauptbildschirm
            return MainScreen(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              onThemeChanged: _toggleDarkMode,
            );
          } else {
            // Benutzer ist abgemeldet, zeige den Login-Bildschirm
            return Profile(
              selectedIndex: 2,
              onItemTapped: _onItemTapped,
              onThemeChanged: _toggleDarkMode,
            );
          }
        },
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
    // Definiere die Seiten nur für angemeldete Benutzer
    final List<Widget> pages = [
      const Home(),
      const Search(),
      UserProfileScreen(
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
