import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

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
            TextField(
              decoration: InputDecoration(
                hintText: "Username",
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),

            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.key_sharp),
                suffixIcon: Icon(Icons.visibility_off),
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
              child: OutlinedButton(onPressed: () => (), child: Text("login")),
            ),
          ],
        ),
      ),
    );
  }
}
