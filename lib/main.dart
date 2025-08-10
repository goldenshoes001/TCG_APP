import 'package:flutter/material.dart';
import 'package:tcg_app/class/appbar.dart';

import 'package:tcg_app/class/bottombar.dart';
import 'package:tcg_app/class/home.dart';
import 'package:tcg_app/class/profile.dart';
import 'package:tcg_app/class/search.dart';
import 'package:tcg_app/class/meta.dart';

import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

void main() {
  runApp(MainApp());
}

// ignore: must_be_immutable
class MainApp extends StatefulWidget {
  const MainApp({super.key});

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
  Widget build(BuildContext context) {
    List<Widget> widgetListe = [Home(), Search(), Profile(), Meta()];
    List<NavigationDestination> iconList = [
      NavigationDestination(icon: Icon(Icons.home), label: "home"),
      NavigationDestination(icon: Icon(Icons.search), label: "search"),
      NavigationDestination(icon: Icon(Icons.person), label: "profile"),
      NavigationDestination(
        icon: Icon(Icons.local_fire_department),
        label: "Meta",
      ),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      themeMode: ThemeMode.system,

      home: Scaffold(
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(MediaQuery.of(context).size.height) / appbarSize,
          child: Barwidget(
            title: "Cardbase",
            titleFlow: MainAxisAlignment.start,
          ),
        ),
        body: widgetListe[_selectedIndex],

        bottomNavigationBar: Bottombar(
          currentIndex: _selectedIndex,
          valueChanged: _onItemTapped,
          navigationItems: iconList,
        ),
      ),
    );
  }
}
