import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tcg_app/class/FirebaseAuthRepository.dart';

import 'package:tcg_app/class/common/user_profile_side.dart';
import 'package:tcg_app/class/registrieren.dart';
import 'package:tcg_app/class/savedata.dart';

class Profile extends StatefulWidget {
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  final int selectedIndex;

  const Profile({
    Key? key,
    required this.onItemTapped,
    required this.onThemeChanged,
    required this.selectedIndex,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final userNameController = TextEditingController();

  bool _isPasswordVisible = false;

  Future<void> handleLogin() async {
    // Die Validierung des Formulars ist der erste Schritt
    if (_formKey.currentState!.validate()) {
      final FirebaseAuthRepository auth = FirebaseAuthRepository();
      final String username = userNameController.text.trim();
      final String password = passwordController.text.trim();

      try {
        await auth.signInWithEmailAndPassword(username, password);

        // Bei erfolgreicher Anmeldung
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Anmeldung erfolgreich!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigiere zum nächsten Bildschirm
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                selectedIndex: widget.selectedIndex,
                onItemTapped: widget.onItemTapped,
                onThemeChanged: widget.onThemeChanged,
                username: username,
              ),
            ),
          );
          passwordController.text = "";
          userNameController.text = "";
        }
      } on Exception catch (e) {
        // Bei einem Fehler, z.B. falsche Anmeldedaten
        String message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 120),
      child: Column(
        children: [
          Text("User Login", style: Theme.of(context).textTheme.headlineLarge),
          Icon(Icons.person, color: theme.cardColor, size: 250),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: "Benutzername",
                      hintText: "Benutzername",
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihre E-Mail-Adresse ein.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Passwort",
                      hintText: "passwort",
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte geben Sie Ihr Passwort ein.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Passwort vergessen?"),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Registrieren(
                                selectedIndex: widget.selectedIndex,
                                onItemTapped: widget.onItemTapped,
                                onThemeChanged: widget.onThemeChanged,
                              ),
                            ),
                          );
                        },
                        child: const Text("Registrieren"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.65,
                    child: OutlinedButton(
                      onPressed: handleLogin,
                      child: const Text("Anmelden"),
                    ),
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
