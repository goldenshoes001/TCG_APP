import 'package:flutter/material.dart';

class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    super.key,
    required this.controller,
    required this.errorstate,
  });
  final TextEditingController controller;
  final bool errorstate;
  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: validatePassword,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Password",
        hintText: "Password",
        prefixIcon: const Icon(Icons.key_sharp),
        errorText: widget.errorstate ? "wrong password" : null,

        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility_off : Icons.visibility_sharp,
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}

String? validatePassword(String? value) {
  final v = value?.trim() ?? "";
  final regex = RegExp(
    r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+\-=\[\]{}|;:,.<>?])[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{}|;:,.<>?]{8,}$',
  );

  if (v.isEmpty || v == "")
    return "pls write a password";
  else if (!regex.hasMatch(v))
    return "pls write a password in the right format \nat least 8 and max 20 charackters \nat least one special charackter and one big letter";
  else
    return null;
}
