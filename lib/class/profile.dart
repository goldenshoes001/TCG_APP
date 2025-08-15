import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/password_field.dart';
import 'package:tcg_app/class/user_site.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isPasswordVisible = false;
  bool errorStatePassword = false;
  bool errorStateUsername = false;
  final _formKey = GlobalKey<FormState>();

  final passwordController = TextEditingController();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();

  void showUserInput() {
    String username = userNameController.text;
    String password = passwordController.text;
    String checkUsername = "Sebastian93!";
    String checkPassword = "IchbineineDose!";
    print("username: $username , password: $password");

    if (username == checkUsername && password == checkPassword) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => UserSite(username: username)),
      );
    } else {
      setState(() {
        if (username == checkUsername && password != checkPassword) {
          errorStateUsername = false;
          errorStatePassword = true;
        } else if (username != checkUsername && password == checkPassword) {
          errorStateUsername = true;
          errorStatePassword = false;
        } else {
          errorStateUsername = true;
          errorStatePassword = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height / 120),
        child: Column(
          children: [
            Text(
              "User Login",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Icon(Icons.person, color: theme.cardColor, size: 250),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: userNameController,
                      validator: (value) {
                        return validateUserName(value);
                      },
                      decoration: InputDecoration(
                        labelText: "Username",
                        hintText: "Username",
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                    SizedBox(height: 10),
                    PasswordInputField(
                      controller: passwordController,
                      errorstate: errorStatePassword,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("forget Password"),
                        SizedBox(width: MediaQuery.of(context).size.width / 2),
                        Text("Registration"),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        return validateEmail(value);
                      },
                      decoration: InputDecoration(
                        labelText: "E-Mail",
                        hintText: "E-Mail",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.65,
                      child: OutlinedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            showUserInput();
                          }
                        },
                        child: Text("login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? validateUserName(String? value) {
    final v = value?.trim() ?? "";
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (v.isEmpty) {
      return "pls write a Username.";
    } else if (!regex.hasMatch(v)) {
      return "The Username is written by : \n -only letters or numbers \n -at least 3 charackters \n -max 20 letters .";
    } else {
      return null;
    }
  }

  String? validateEmail(String? value) {
    final v = value?.trim() ?? "";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (v.isEmpty) {
      return "pls write in an email";
    } else if (!emailRegex.hasMatch(v)) {
      return "pls writein an accurate email";
    } else {
      return null;
    }
  }
}

// Der Code für PasswordInputField und die anderen Klassen muss auch vorhanden sein.
