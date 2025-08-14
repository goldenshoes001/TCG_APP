import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:tcg_app/class/common/appbar.dart';

import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';

import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

void main() {
  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return MainApp();
      },
    ),
  );
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
