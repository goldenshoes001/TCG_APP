import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/lists.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/light_theme.dart';
import 'package:tcg_app/theme/sizing.dart';

class UserSite extends StatefulWidget {
  UserSite({super.key, required this.username});

  String username;

  @override
  State<UserSite> createState() => UsersiteState();
}

class UsersiteState extends State<UserSite> {
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
            titleFlow: MainAxisAlignment.center,
          ),
        ),
        body: Text(
          "${widget.username}  willkommen auf deiner persönlichen Seite Seite",
        ),

        bottomNavigationBar: Bottombar(
          currentIndex: _selectedIndex,
          valueChanged: _onItemTapped,
          navigationItems: iconList,
        ),
      ),
    );
  }
}
