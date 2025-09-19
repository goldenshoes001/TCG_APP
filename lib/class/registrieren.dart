import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/theme/sizing.dart';
// Importiere deine FirebaseAuthRepository
import 'package:tcg_app/class/FirebaseAuthRepository.dart';

// Stelle sicher, dass du das Benutzerprofil importierst
import 'package:tcg_app/class/common/user_profile_side.dart';

class Registrieren extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  const Registrieren({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onThemeChanged,
  });

  @override
  State<Registrieren> createState() => _RegistrierenState();
}

class _RegistrierenState extends State<Registrieren> {
  final _formKey = GlobalKey<FormState>();

  final emailAdressController = TextEditingController();
  final repeatEmailAdressController = TextEditingController();
  final pwController = TextEditingController();
  final pwRepeatController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;

  // Live validation states
  String _emailValidation = "";
  Color _emailValidationColor = Colors.grey;
  String _repeatEmailValidation = "";
  Color _repeatEmailValidationColor = Colors.grey;
  String _passwordStrength = "";
  Color _passwordStrengthColor = Colors.grey;
  String _repeatPasswordValidation = "";
  Color _repeatPasswordValidationColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Listener für Live-Validierung
    emailAdressController.addListener(_validateEmail);
    repeatEmailAdressController.addListener(_validateRepeatEmail);
    pwController.addListener(_validatePassword);
    pwRepeatController.addListener(_validateRepeatPassword);
  }

  @override
  void dispose() {
    emailAdressController.removeListener(_validateEmail);
    repeatEmailAdressController.removeListener(_validateRepeatEmail);
    pwController.removeListener(_validatePassword);
    pwRepeatController.removeListener(_validateRepeatPassword);

    emailAdressController.dispose();
    repeatEmailAdressController.dispose();
    pwController.dispose();
    pwRepeatController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    String email = emailAdressController.text.trim();
    String validation = "";
    Color color = Colors.grey;

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );

    if (email.isEmpty) {
      validation = "E-Mail-Adresse eingeben";
      color = Colors.grey;
    } else if (!emailRegex.hasMatch(email)) {
      validation = "Ungültige E-Mail-Adresse";
      color = Colors.red;
    } else if (email.length > 254) {
      validation = "E-Mail-Adresse zu lang";
      color = Colors.red;
    } else {
      validation = "Gültige E-Mail-Adresse";
      color = Colors.green;
    }

    if (_emailValidation != validation) {
      setState(() {
        _emailValidation = validation;
        _emailValidationColor = color;
      });
      _showValidationSnackBar("E-Mail: $_emailValidation", color);
    }

    if (repeatEmailAdressController.text.isNotEmpty) {
      _validateRepeatEmail();
    }
  }

  void _validateRepeatEmail() {
    String email = emailAdressController.text.trim();
    String repeatEmail = repeatEmailAdressController.text.trim();
    String validation = "";
    Color color = Colors.grey;

    if (repeatEmail.isEmpty) {
      validation = "E-Mail wiederholen";
      color = Colors.grey;
    } else if (repeatEmail != email) {
      validation = "E-Mail-Adressen stimmen nicht überein";
      color = Colors.red;
    } else {
      validation = "E-Mail-Adressen stimmen überein";
      color = Colors.green;
    }

    if (_repeatEmailValidation != validation) {
      setState(() {
        _repeatEmailValidation = validation;
        _repeatEmailValidationColor = color;
      });
      _showValidationSnackBar(
        "E-Mail Bestätigung: $_repeatEmailValidation",
        color,
      );
    }
  }

  void _validatePassword() {
    String password = pwController.text;
    String strength = "";
    Color color = Colors.grey;

    if (password.isEmpty) {
      strength = "Passwort eingeben";
      color = Colors.grey;
    } else if (password.length < 6) {
      strength = "Zu kurz (min. 6 Zeichen)";
      color = Colors.red;
    } else {
      int score = 0;
      List<String> missingRequirements = [];

      if (RegExp(r'[a-z]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("Kleinbuchstaben");
      }

      if (RegExp(r'[A-Z]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("Großbuchstaben");
      }

      if (RegExp(r'[0-9]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("Zahlen");
      }

      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("Sonderzeichen");
      }

      if (missingRequirements.isNotEmpty) {
        strength = "Benötigt: ${missingRequirements.join(', ')}";
        color = score >= 2 ? Colors.orange : Colors.red;
      } else {
        strength = "Stark - Alle Anforderungen erfüllt";
        color = Colors.green;
      }
    }

    if (_passwordStrength != strength) {
      setState(() {
        _passwordStrength = strength;
        _passwordStrengthColor = color;
      });
      _showValidationSnackBar("Passwort: $_passwordStrength", color);
    }

    if (pwRepeatController.text.isNotEmpty) {
      _validateRepeatPassword();
    }
  }

  void _validateRepeatPassword() {
    String password = pwController.text;
    String repeatPassword = pwRepeatController.text;
    String validation = "";
    Color color = Colors.grey;

    if (repeatPassword.isEmpty) {
      validation = "Passwort bestätigen";
      color = Colors.grey;
    } else if (repeatPassword != password) {
      validation = "Passwörter stimmen nicht überein";
      color = Colors.red;
    } else {
      validation = "Passwörter stimmen überein";
      color = Colors.green;
    }

    if (_repeatPasswordValidation != validation) {
      setState(() {
        _repeatPasswordValidation = validation;
        _repeatPasswordValidationColor = color;
      });
      _showValidationSnackBar(
        "Passwort Bestätigung: $_repeatPasswordValidation",
        color,
      );
    }
  }

  void _showValidationSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                  ? Icons.error
                  : color == Colors.orange
                  ? Icons.warning
                  : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    if (index != widget.selectedIndex) {
      Navigator.pop(context);
      widget.onItemTapped(index);
    }
  }

  Future<void> handleRegistrieren() async {
    // 1. Zuerst die Live-Validierung prüfen
    if (_emailValidationColor != Colors.green ||
        _repeatEmailValidationColor != Colors.green ||
        _passwordStrengthColor != Colors.green ||
        _repeatPasswordValidationColor != Colors.green) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bitte korrigieren Sie alle Fehler vor der Registrierung.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Formular-Validierung
    if (_formKey.currentState!.validate()) {
      final FirebaseAuthRepository auth = FirebaseAuthRepository();
      final String email = emailAdressController.text.trim();
      final String password = pwController.text;

      try {
        await auth.createUserWithEmailAndPassword(email, password);

        // Bei erfolgreicher Registrierung
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrierung erfolgreich!"),
            backgroundColor: Colors.green,
          ),
        );

        // Nach der Registrierung zum Profilbildschirm wechseln
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                selectedIndex: widget.selectedIndex,
                onItemTapped: widget.onItemTapped,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
          emailAdressController.clear();
          repeatEmailAdressController.clear();
          pwController.clear();
          pwRepeatController.clear();
        }
      } on Exception catch (e) {
        // Fehler von Firebase abfangen
        String message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = 30;

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // E-Mail Feld
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.mail),
                          labelText: "Email :",
                          hintText: "Email",
                          suffixIcon: _emailValidation.isNotEmpty
                              ? Icon(
                                  _emailValidationColor == Colors.green
                                      ? Icons.check_circle
                                      : _emailValidationColor == Colors.red
                                      ? Icons.error
                                      : Icons.warning,
                                  color: _emailValidationColor,
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte geben Sie eine E-Mail-Adresse ein';
                          }
                          return null;
                        },
                        controller: emailAdressController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_emailValidation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _emailValidation,
                              style: TextStyle(
                                color: _emailValidationColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: height),

                      // E-Mail wiederholen
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.mail),
                          labelText: "E-Mail wiederholen :",
                          hintText: "E-Mail wiederholen",
                          suffixIcon: _repeatEmailValidation.isNotEmpty
                              ? Icon(
                                  _repeatEmailValidationColor == Colors.green
                                      ? Icons.check_circle
                                      : _repeatEmailValidationColor ==
                                            Colors.red
                                      ? Icons.error
                                      : Icons.warning,
                                  color: _repeatEmailValidationColor,
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte wiederholen Sie die E-Mail-Adresse';
                          }
                          return null;
                        },
                        controller: repeatEmailAdressController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_repeatEmailValidation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _repeatEmailValidation,
                              style: TextStyle(
                                color: _repeatEmailValidationColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: height),

                      // Passwort Feld
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.key),
                          labelText: "Passwort :",
                          hintText: "Passwort",
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_passwordStrength.isNotEmpty)
                                Icon(
                                  _passwordStrengthColor == Colors.green
                                      ? Icons.check_circle
                                      : _passwordStrengthColor == Colors.red
                                      ? Icons.error
                                      : _passwordStrengthColor == Colors.orange
                                      ? Icons.warning
                                      : Icons.info,
                                  color: _passwordStrengthColor,
                                  size: 20,
                                ),
                              IconButton(
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
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte geben Sie ein Passwort ein';
                          }
                          return null;
                        },
                        controller: pwController,
                        obscureText: !_isPasswordVisible,
                      ),
                      if (_passwordStrength.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _passwordStrength,
                              style: TextStyle(
                                color: _passwordStrengthColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: height),

                      // Passwort wiederholen
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.key),
                          labelText: "Passwort wiederholen :",
                          hintText: "Passwort wiederholen",
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_repeatPasswordValidation.isNotEmpty)
                                Icon(
                                  _repeatPasswordValidationColor == Colors.green
                                      ? Icons.check_circle
                                      : _repeatPasswordValidationColor ==
                                            Colors.red
                                      ? Icons.error
                                      : Icons.warning,
                                  color: _repeatPasswordValidationColor,
                                  size: 20,
                                ),
                              IconButton(
                                icon: Icon(
                                  _isRepeatPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isRepeatPasswordVisible =
                                        !_isRepeatPasswordVisible;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bitte bestätigen Sie Ihr Passwort';
                          }
                          return null;
                        },
                        controller: pwRepeatController,
                        obscureText: !_isRepeatPasswordVisible,
                      ),
                      if (_repeatPasswordValidation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _repeatPasswordValidation,
                              style: TextStyle(
                                color: _repeatPasswordValidationColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: height + 50),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.96,
                  child: OutlinedButton(
                    onPressed: handleRegistrieren,
                    child: const Text("Registrieren"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Bottombar(
        currentIndex: widget.selectedIndex,
        valueChanged: _handleBottomNavigation,
        navigationItems: iconList,
      ),
    );
  }
}
