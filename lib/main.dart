import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/common/user_profile_side.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/class/home.dart';
import 'package:tcg_app/class/search.dart';
import 'package:tcg_app/class/login.dart';
import 'package:tcg_app/class/meta.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
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
  User? _currentUser; // Add current user state

  @override
  void initState() {
    super.initState();
    _loadData();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
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

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const Home();
      case 1:
        return const Search();
      case 2:
        if (_currentUser != null) {
          // Angemeldet - zeige Profil
          return UserProfileScreen(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onThemeChanged: _toggleDarkMode,
          );
        } else {
          // Nicht angemeldet - zeige Login
          return Profile(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onThemeChanged: _toggleDarkMode,
          );
        }
      case 3:
        return const Meta();
      default:
        return const Home();
    }
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
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.height / appbarSize,
          ),
          child: Barwidget(
            title: "Cardbase",
            titleFlow: MainAxisAlignment.start,
            onThemeChanged: _toggleDarkMode,
          ),
        ),
        body: _buildPage(),
        bottomNavigationBar: Bottombar(
          currentIndex: _selectedIndex,
          valueChanged: _onItemTapped,
          navigationItems: iconList,
        ),
      ),
    );
  }
}
