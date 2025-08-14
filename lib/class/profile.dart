import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final passwordController = TextEditingController();
    final userNameController = TextEditingController();

    void showUserInput() {
      String username = userNameController.text;
      String password = passwordController.text;
      String checkUsername = "test";
      String checkPassword = "test";
      print("username: $username , password: $password");

      if (username == checkUsername && password == checkPassword) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserSite(username: username)),
        );
      } else {
        setState(() {
          if (username != checkUsername && password == checkPassword) {
            errorStateUsername = true;
            errorStatePassword = false;
          } else if (password != checkPassword && username == checkUsername) {
            errorStatePassword = true;
            errorStateUsername = false;
          } else {
            errorStatePassword = true;
            errorStateUsername = true;
          }
        });
      }
    }

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
            TextField(
              controller: userNameController,

              decoration: InputDecoration(
                errorText: errorStateUsername ? "wrong username" : null,
                hintText: "Username",
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),

            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,

              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.key_sharp),
                errorText: errorStatePassword ? "wrong password" : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility_sharp,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("forget Password"),
                SizedBox(width: MediaQuery.of(context).size.width / 2),
                Text("Registration"),
              ],
            ),
            SizedBox(height: 40),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: OutlinedButton(
                onPressed: showUserInput,
                child: Text("login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
