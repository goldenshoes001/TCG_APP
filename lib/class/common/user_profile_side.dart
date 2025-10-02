import 'package:flutter/material.dart';

import 'package:tcg_app/class/FirebaseAuthRepository.dart';
import 'package:tcg_app/class/common/user.dart';

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
  final Userdata userdb = Userdata();
  final authRepo = FirebaseAuthRepository();
  late final Future<Map<String, dynamic>> userData;

  String? email;
  String? uid;

  @override
  void initState() {
    super.initState();
    final currentUser = authRepo.getCurrentUser();

    if (currentUser != null) {
      uid = currentUser.uid;
      email = currentUser.displayName ?? currentUser.email;

      userData = userdb.readUser(uid!);
    } else {
      uid = null;
      email = "Gast";
      userData = Future.value({}); // Leere Map als Fallback
    }
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

        // Weiterleiten des Benutzers zur Anmeldeseite/Homescreen
        widget.onItemTapped(2);
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
          // KORREKTE IMPLEMENTIERUNG DER FUTUREBUILDER
          // Der Typ ist jetzt Future<Map<String, dynamic>>
          FutureBuilder<Map<String, dynamic>>(
            future: userData,
            builder: (BuildContext context, snapshot) {
              // 1. Ladezustand: Wenn die Daten noch nicht da sind
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Lade Benutzerprofil..."),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Text('Fehler beim Laden der Userdaten');
              }

              if (snapshot.hasData) {
                final userMap = snapshot.data!;

                return Column(
                  children: [
                    Text(
                      'Willkommen, ${userMap['username'] ?? email ?? "Benutzer"}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('E-Mail: ${userMap['email'] ?? ""}'),
                    Text('username: ${userMap['username'] ?? ""}'),
                    Text('Benutzer-ID: ${userMap['userId'] ?? ""}'),
                  ],
                );
              }

              return const Text("Keine Profilinformationen verfügbar.");
            },
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _handleLogout,
            child: const Text("Abmelden"),
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: deleteUser,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text("Account löschen"),
          ),
        ],
      ),
    );
  }

  void deleteUser() {
    final userdb = Userdata();
    final currentUser = authRepo.getCurrentUser()!.uid;

    userdb.deleteUserCompletely(currentUser);
  }
}
