import 'package:flutter/material.dart';
import 'package:tcg_app/theme/dark_theme.dart';
import 'package:tcg_app/theme/light_theme.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 350),
            TextField(
              decoration: InputDecoration(
                hintText: "Suchen...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 50),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? theme.darkColorOfContainer
                    : theme.lightColorOfContainer,
              ),
              width: MediaQuery.of(context).size.width / 0.5,
              height: MediaQuery.of(context).size.height / 1.7,

              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Ergebnisse werden hier angezeigt...",
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
