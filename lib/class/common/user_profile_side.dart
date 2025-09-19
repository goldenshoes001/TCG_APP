import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/class/FirebaseAuthRepository.dart';

class UserProfileScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  const UserProfileScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onThemeChanged,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  void _fetchUsername() {
    final authRepo = FirebaseAuthRepository();
    final currentUser = authRepo.getCurrentUser();

    String? name = currentUser?.displayName;
    if (name == null || name.isEmpty) {
      name = currentUser?.email;
    }

    setState(() {
      _username = name;
    });
  }

  Future<void> _handleLogout() async {
    final authRepo = FirebaseAuthRepository();
    try {
      await authRepo.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sie wurden erfolgreich abgemeldet."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Abmelden: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            Text(
              "Willkommen, ${_username ?? 'Gast'}!",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.lightBlue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Benutzer: ${_username ?? 'Nicht angemeldet'}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _handleLogout,
                      child: const Text("Abmelden"),
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
        // Die Bottombar ruft jetzt direkt die onItemTapped-Methode auf
        valueChanged: widget.onItemTapped,
        navigationItems: iconList,
      ),
    );
  }
}
