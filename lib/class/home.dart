import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Willkommen bei \n Cardbase", textAlign: TextAlign.center),
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        Image.asset(
          'assets/icon/appicon.png',
          height: MediaQuery.of(context).size.height * 0.38,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
        Text("Ihrer TCG App des Vertrauens"),
      ],
    );
  }
}
