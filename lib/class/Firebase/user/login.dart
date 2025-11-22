import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/Firebase/user/registrieren.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Profile extends ConsumerStatefulWidget {
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;
  final int selectedIndex;

  const Profile({
    super.key,
    required this.onItemTapped,
    required this.onThemeChanged,
    required this.selectedIndex,
  });

  @override
  ConsumerState<Profile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
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
      final auth = ref.read(authRepositoryProvider);
      final String username = userNameController.text.trim();
      final String password = passwordController.text.trim();

      try {
        await auth.signInWithEmailAndPassword(username, password);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login successful!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          passwordController.clear();
          userNameController.clear();
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
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 120),
      child: Column(
        children: [
          const Icon(Icons.person, size: 250),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      hintText: "Username",
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pls write a E-mail adress';
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
                        return 'Pls write a password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
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
                        child: const Text("Registration"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.65,
                    child: OutlinedButton(
                      onPressed: handleLogin,
                      child: const Text("Login"),
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
