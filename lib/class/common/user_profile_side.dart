import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/theme/sizing.dart';

class UserProfileScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  final Function(bool) onThemeChanged;
  final String username;

  const UserProfileScreen({
    super.key,

    required this.selectedIndex,
    required this.onItemTapped,

    required this.onThemeChanged,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Neue Methode für die Navigation
  void _handleBottomNavigation(int index) {
    if (index != widget.selectedIndex) {
      // Zurück zum Hauptscreen navigieren und den gewählten Index setzen
      Navigator.pop(context);
      widget.onItemTapped(index);
    }
    // Wenn derselbe Index gewählt wird (Profil), bleiben wir auf dieser Seite
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height / appbarSize,
        ),
        child: Barwidget(
          title: "cardbase",
          titleFlow: MainAxisAlignment.start,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Willkommensnachricht
            Text(
              "Willkommen, ${widget.username}!",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // Profilinformationen
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.person, size: 100, color: Colors.lightBlue),
                    const SizedBox(height: 10),
                    Text(
                      "Benutzername: ${widget.username}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),

                    // Logout Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Abmelden"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Bottombar(
        currentIndex: widget.selectedIndex,
        valueChanged: _handleBottomNavigation, // Neue Methode verwenden
        navigationItems: iconList,
      ),
    );
  }
}
