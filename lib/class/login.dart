import 'package:flutter/material.dart';
import 'package:tcg_app/class/FirebaseAuthRepository.dart';

import 'package:tcg_app/class/registrieren.dart';

class Profile extends StatefulWidget {
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;
  final int selectedIndex;

  const Profile({
    Key? key,
    required this.onItemTapped,
    required this.onThemeChanged,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final userNameController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    passwordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final FirebaseAuthRepository auth = FirebaseAuthRepository();
      final String username = userNameController.text.trim();
      final String password = passwordController.text.trim();

      try {
        await auth.signInWithEmailAndPassword(username, password);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Anmeldung erfolgreich!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          passwordController.clear();
          userNameController.clear();
          
          // No need for manual navigation
        }
      } on Exception catch (e) {
        String message = e.toString().replaceFirst('Exception: ', '');
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
