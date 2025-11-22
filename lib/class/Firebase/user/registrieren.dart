import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/Firebase/user/user.dart';
import 'package:tcg_app/class/common/appbar.dart';
import 'package:tcg_app/class/common/bottombar.dart';
import 'package:tcg_app/class/common/lists.dart';
import 'package:tcg_app/theme/sizing.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Registrieren extends ConsumerStatefulWidget {
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
  ConsumerState<Registrieren> createState() => _RegistrierenState();
}

class _RegistrierenState extends ConsumerState<Registrieren> {
  final _formKey = GlobalKey<FormState>();

  final emailAdressController = TextEditingController();
  final usernameController = TextEditingController();
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
    usernameController.dispose();
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
      validation = "Enter email address";
      color = Colors.grey;
    } else if (!emailRegex.hasMatch(email)) {
      validation = "Invalid email address";
      color = Colors.red;
    } else if (email.length > 254) {
      validation = "Email address too long";
      color = Colors.red;
    } else {
      validation = "Valid email address";
      color = Colors.green;
    }

    if (_emailValidation != validation) {
      setState(() {
        _emailValidation = validation;
        _emailValidationColor = color;
      });
      _showValidationSnackBar("Email: $_emailValidation", color);
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
      validation = "Repeat email";
      color = Colors.grey;
    } else if (repeatEmail != email) {
      validation = "Email addresses do not match";
      color = Colors.red;
    } else {
      validation = "Email addresses match";
      color = Colors.green;
    }

    if (_repeatEmailValidation != validation) {
      setState(() {
        _repeatEmailValidation = validation;
        _repeatEmailValidationColor = color;
      });
      _showValidationSnackBar(
        "Email Confirmation: $_repeatEmailValidation",
        color,
      );
    }
  }

  void _validatePassword() {
    String password = pwController.text;
    String strength = "";
    Color color = Colors.grey;

    if (password.isEmpty) {
      strength = "Enter password";
      color = Colors.grey;
    } else if (password.length < 6) {
      strength = "Too short (min. 6 characters)";
      color = Colors.red;
    } else {
      int score = 0;
      List<String> missingRequirements = [];

      if (RegExp(r'[a-z]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("lowercase letters");
      }

      if (RegExp(r'[A-Z]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("uppercase letters");
      }

      if (RegExp(r'[0-9]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("numbers");
      }

      if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
        score++;
      } else {
        missingRequirements.add("special characters");
      }

      if (missingRequirements.isNotEmpty) {
        strength = "Required: ${missingRequirements.join(', ')}";
        color = score >= 2 ? Colors.orange : Colors.red;
      } else {
        strength = "Strong - All requirements met";
        color = Colors.green;
      }
    }

    if (_passwordStrength != strength) {
      setState(() {
        _passwordStrength = strength;
        _passwordStrengthColor = color;
      });
      _showValidationSnackBar("Password: $_passwordStrength", color);
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
      validation = "Confirm password";
      color = Colors.grey;
    } else if (repeatPassword != password) {
      validation = "Passwords do not match";
      color = Colors.red;
    } else {
      validation = "Passwords match";
      color = Colors.green;
    }

    if (_repeatPasswordValidation != validation) {
      setState(() {
        _repeatPasswordValidation = validation;
        _repeatPasswordValidationColor = color;
      });
      _showValidationSnackBar(
        "Password Confirmation: $_repeatPasswordValidation",
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
    // 1. First check live validation
    if (_emailValidationColor != Colors.green ||
        _repeatEmailValidationColor != Colors.green ||
        _passwordStrengthColor != Colors.green ||
        _repeatPasswordValidationColor != Colors.green) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please correct all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Form validation
    if (_formKey.currentState!.validate()) {
      final auth = ref.read(authRepositoryProvider);
      final db = Userdata();
      final String email = emailAdressController.text.trim();
      final String password = pwController.text;
      final String username = usernameController.text;

      try {
        await auth.createUserWithEmailAndPassword(email, password);
        final String userId = auth.getCurrentUser()!.uid;
        await db.createUser(username, email, userId);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful!"),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          emailAdressController.clear();
          usernameController.clear();
          repeatEmailAdressController.clear();
          pwController.clear();
          pwRepeatController.clear();

          Navigator.pop(context);
          widget.onItemTapped(2);
        }
      } on Exception catch (e) {
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.boy_sharp),
                      labelText: "Username",
                      hintText: "Username",
                    ),
                    controller: usernameController,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail),
                      labelText: "Email",
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
                        return 'Please enter an email address';
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
                        child: Text(_emailValidation),
                      ),
                    ),
                  const SizedBox(height: height),

                  // Repeat Email
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail),
                      labelText: "Repeat Email",
                      hintText: "Repeat Email",
                      suffixIcon: _repeatEmailValidation.isNotEmpty
                          ? Icon(
                              _repeatEmailValidationColor == Colors.green
                                  ? Icons.check_circle
                                  : _repeatEmailValidationColor == Colors.red
                                  ? Icons.error
                                  : Icons.warning,
                              color: _repeatEmailValidationColor,
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please repeat the email address';
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
                        child: Text(_repeatEmailValidation),
                      ),
                    ),
                  const SizedBox(height: height),

                  // Password Field
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.key),
                      labelText: "Password",
                      hintText: "Password",
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
                        return 'Please enter a password';
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
                        child: Text(_passwordStrength),
                      ),
                    ),
                  const SizedBox(height: height),

                  // Repeat Password
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.key),
                      labelText: "Repeat Password",
                      hintText: "Repeat Password",
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_repeatPasswordValidation.isNotEmpty)
                            Icon(
                              _repeatPasswordValidationColor == Colors.green
                                  ? Icons.check_circle
                                  : _repeatPasswordValidationColor == Colors.red
                                  ? Icons.error
                                  : _repeatPasswordValidationColor ==
                                        Colors.orange
                                  ? Icons.warning
                                  : Icons.info,
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
                        return 'Please confirm your password';
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
                        child: Text(_repeatPasswordValidation),
                      ),
                    ),

                  const SizedBox(height: height + 50),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.96,
                    child: OutlinedButton(
                      onPressed: handleRegistrieren,
                      child: const Text("Register"),
                    ),
                  ),
                ],
              ),
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
