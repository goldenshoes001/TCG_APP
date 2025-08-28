import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/password_field.dart';
import 'package:tcg_app/class/common/user_profile_side.dart';
import 'package:tcg_app/class/savedata.dart';

class Profile extends StatefulWidget {
  final SaveData data;
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  final int selectedIndex;

  const Profile({
    super.key,
    required this.data,
    required this.onItemTapped,
    required this.onThemeChanged,
 
    required this.selectedIndex,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();

  var passwordController = TextEditingController();
  var userNameController = TextEditingController();

  // The login and navigation logic is now handled in the onPressed callback.
  void handleLogin() {
    if (_formKey.currentState!.validate()) {
      String checkUsername = "Sebastian93";
      String checkPassword = "Thermaltake14!";

      String username = userNameController.text.trim();
      String password = passwordController.text.trim();

      if (username == checkUsername && password == checkPassword) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              data: widget.data,
              selectedIndex: widget.selectedIndex,
              onItemTapped: widget.onItemTapped,
           
              onThemeChanged: widget.onThemeChanged,
              username: username,
            ),
          ),
        );
        passwordController.text = "";
        userNameController.text = "";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Benutzername oder Passwort ist falsch."),
            backgroundColor: Colors.red,
          ),
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
                    validator: (value) {
                      final v = value?.trim() ?? "";
                      final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
                      if (v.isEmpty) {
                        return "Bitte einen Benutzernamen eingeben.";
                      } else if (!regex.hasMatch(v)) {
                        return "Benutzername ungültig:\n- Nur Buchstaben, Zahlen oder Unterstrich\n- 3 bis 20 Zeichen.";
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: "Benutzername",
                      hintText: "Benutzername",
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PasswordInputField(
                    controller: passwordController,

                    errorstate: false,
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Text("Passwort vergessen?"),
                      Spacer(),
                      Text("Registrieren"),
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
