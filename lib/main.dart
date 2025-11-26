import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/Firebase/user/login.dart';
import 'package:tcg_app/class/Firebase/user/user_profile_side.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/sharedPreference.dart';
import 'package:tcg_app/class/widgets/home.dart';
import 'package:tcg_app/class/widgets/calculator.dart';
import 'package:tcg_app/class/widgets/search.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SaveData.initPreferences();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SaveData data = SaveData();
  final CardData _cardData = CardData();

  bool? isDarkMode;
  int _selectedIndex = 0;
  User? _currentUser;

  // Preload Status
  bool _isPreloading = true;
  String _loadingMessage = 'loading App...';

  // Preloaded Data
  Map<String, List<dynamic>>? _tcgBannlist;
  Map<String, List<dynamic>>? _ocgBannlist;
  List<Map<String, dynamic>>? _allDecks; // ✅ NEU: Alle Decks

  @override
  void initState() {
    super.initState();
    _loadData();
    _preloadAppData();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      } else {
        FirebaseAuth.instance.signInAnonymously();
      }
    });
  }

  Future<void> _loadData() async {
    final loadedMode = await data.loadBool("darkMode");
    if (mounted) {
      setState(() {
        isDarkMode = loadedMode;
      });
    }
  }

  Future<void> _preloadAppData() async {
    try {
      // 1. Lade Bannlisten
      setState(() {
        _loadingMessage = 'TCG Banlist is loading..';
      });
      _tcgBannlist = await _cardData.sortTCGBannCards();

      setState(() {
        _loadingMessage = 'OCG Banlist is loading...';
      });
      _ocgBannlist = await _cardData.sortOCGBannCards();

      // 2. Preload Bannlisten-Bilder
      setState(() {
        _loadingMessage = 'loading Cardimages...';
      });
      await _preloadBannlistImages();

      // 3. Lade Filter-Daten (werden von Riverpod Providern geladen)
      setState(() {
        _loadingMessage = 'loading Filteroptions..';
      });

      // Filter werden jetzt über Provider geladen, kein direktes Speichern mehr nötig
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ 4. LADE ALLE DECKS
      setState(() {
        _loadingMessage = 'loading all Decks...';
      });
      await _preloadAllDecks();

      // Fertig!
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Preloading: $e');
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    }
  }

  // ✅ NEU: Lädt alle Decks beim App-Start
  Future<void> _preloadAllDecks() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(200) // Limitiere auf 200 neueste Decks
          .get();

      _allDecks = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print('✅ ${_allDecks?.length ?? 0} Decks vorgeladen');
    } catch (e) {
      print('❌ Fehler beim Laden der Decks: $e');
      _allDecks = [];
    }
  }

  Future<void> _preloadBannlistImages() async {
    final allCards = [
      ...(_tcgBannlist?['banned'] ?? []),
      ...(_tcgBannlist?['limited'] ?? []),
      ...(_tcgBannlist?['semiLimited'] ?? []),
      ...(_ocgBannlist?['banned'] ?? []),
      ...(_ocgBannlist?['limited'] ?? []),
      ...(_ocgBannlist?['semiLimited'] ?? []),
    ];

    try {
      await _cardData.preloadCardImages(
        allCards.cast<Map<String, dynamic>>(),
        maxCards: 100,
      );
    } catch (e) {
      print('Fehler beim Preload der Bilder: $e');
    }
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
        return Home(
          preloadedTCGBannlist: _tcgBannlist,
          preloadedOCGBannlist: _ocgBannlist,
        );
      case 1:
        return Search(
          preloadedDecks: _allDecks,
        ); // ✅ Übergebe vorgeladene Decks
      case 2:
        if (_currentUser != null) {
          return UserProfileScreen(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onThemeChanged: _toggleDarkMode,
          );
        } else {
          return Profile(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
            onThemeChanged: _toggleDarkMode,
          );
        }
      case 3:
        return const ProbabilityCalculator();
      default:
        return Home(
          preloadedTCGBannlist: _tcgBannlist,
          preloadedOCGBannlist: _ocgBannlist,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreloading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        themeMode: isDarkMode == null
            ? ThemeMode.system
            : (isDarkMode! ? ThemeMode.dark : ThemeMode.light),
        home: Scaffold(
          body: Container(
            color: Color(0xFF0d1421),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _loadingMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: isDarkMode == null
          ? ThemeMode.system
          : (isDarkMode! ? ThemeMode.dark : ThemeMode.light),
      home: SafeArea(
        child: Scaffold(
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
      ),
    );
  }
}
