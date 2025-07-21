import 'package:flutter/material.dart';
import 'package:tcg_app/class/appdata.dart';
import 'package:tcg_app/class/text_widget.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextWidget(
          text: "Willkommen bei",
          fontSize: Appdata.header,
          fontWeight: Appdata.bold,
          color: Appdata.textColor,
        ),
        SizedBox(height: Appdata.differenceBetweenImageText),
        Image.asset('assets/images/appicon.png'),
        SizedBox(height: Appdata.differenceBetweenImageText),
        TextWidget(
          text: "Ihrer TCG App des Vertrauens",
          fontSize: Appdata.textSize,
          color: Appdata.textColor,
        ),
      ],
    );
  }
}
