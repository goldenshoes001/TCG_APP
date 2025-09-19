import 'package:flutter/material.dart';
import 'package:tcg_app/class/FirebaseAuthRepository.dart';
import 'package:tcg_app/class/login.dart';

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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sie wurden erfolgreich abgemeldet."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        widget.onItemTapped(2); // Switch to profile tab which will show login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Abmelden: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  const Icon(Icons.person, size: 100, color: Colors.lightBlue),
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
    );
  }
}
