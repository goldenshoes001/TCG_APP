import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/class/common/user_profile_side.dart';

import 'package:tcg_app/theme/sizing.dart';

class UserSite extends StatefulWidget {
  const UserSite({super.key, required this.username});
  final String username;
  @override
  State<UserSite> createState() => _UsersiteState();
}

class _UsersiteState extends State<UserSite> {
  int _selectedIndex = 4;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_selectedIndex == 4) {
      bodyContent = UserProfileSide(username: widget.username);
    } else {
      bodyContent = widgetListe[_selectedIndex];
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height / appbarSize,
        ),
        child: Barwidget(title: "Cardbase", titleFlow: MainAxisAlignment.start),
      ),

      body: bodyContent,

      bottomNavigationBar: Bottombar(
        currentIndex: _selectedIndex,
        valueChanged: _onItemTapped,
        navigationItems: iconList,
      ),
    );
  }
}
