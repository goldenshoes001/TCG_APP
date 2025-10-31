import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/user/login.dart';
import 'package:tcg_app/class/Firebase/user/user_profile_side.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/sharedPreference.dart';
import 'package:tcg_app/class/widgets/home.dart';
import 'package:tcg_app/class/widgets/meta.dart';
import 'package:tcg_app/class/widgets/search.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

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
  final CardData _cardData = CardData();

  bool? isDarkMode;
  int _selectedIndex = 0;
  User? _currentUser;

  // Preload Status
  bool _isPreloading = true;
  String _loadingMessage = 'App wird geladen...';

  // Preloaded Data
  Map<String, List<dynamic>>? _tcgBannlist;
  Map<String, List<dynamic>>? _ocgBannlist;
  List<String>? _types;
  List<String>? _races;
  List<String>? _attributes;
  List<String>? _archetypes;

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
        _loadingMessage = 'Lade TCG Bannliste...';
      });
      _tcgBannlist = await _cardData.sortTCGBannCards();

      setState(() {
        _loadingMessage = 'Lade OCG Bannliste...';
      });
      _ocgBannlist = await _cardData.sortOCGBannCards();

      // 2. Preload Bannlisten-Bilder
      setState(() {
        _loadingMessage = 'Lade Kartenbilder...';
      });
      await _preloadBannlistImages();

      // 3. Lade Filter-Daten
      setState(() {
        _loadingMessage = 'Lade Filter-Optionen...';
      });

      final results = await Future.wait([
        _cardData.getFacetValues('type'),
        _cardData.getFacetValues('race'),
        _cardData.getFacetValues('attribute'),
        _cardData.getFacetValues('archetype'),
      ]);

      _types = results[0];
      _races = results[1];
      _attributes = results[2];
      _archetypes = results[3];

      // Fertig!
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Preloading: $e');
      // Bei Fehler trotzdem fortfahren
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
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

    // Preload erste 20 Bilder (um nicht zu lange zu warten)
    final imagesToPreload = allCards.take(20);

    for (var card in imagesToPreload) {
      try {
        if (card["card_images"] != null &&
            card["card_images"] is List &&
            card["card_images"].isNotEmpty) {
          final imageUrl = card["card_images"][0]["image_url"];
          if (imageUrl != null && imageUrl.toString().isNotEmpty) {
            await _cardData.getImgPath(imageUrl);
          }
        }
      } catch (e) {
        // Ignoriere Fehler einzelner Bilder
        continue;
      }
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
        return const Search();
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
        return Meta(
          preloadedTypes: _types,
          preloadedRaces: _races,
          preloadedAttributes: _attributes,
          preloadedArchetypes: _archetypes,
        );
      default:
        return Home(
          preloadedTCGBannlist: _tcgBannlist,
          preloadedOCGBannlist: _ocgBannlist,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Zeige Ladebildschirm während Preloading
    if (_isPreloading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        themeMode: isDarkMode == null
            ? ThemeMode.system
            : (isDarkMode! ? ThemeMode.dark : ThemeMode.light),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _loadingMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normale App nach Preloading
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
