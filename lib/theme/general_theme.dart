import 'package:flutter/material.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme(BuildContext context) {
  return ThemeData(
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.all(0),
      shadowColor: Colors.transparent,
      clipBehavior: Clip.none,
    ),
    tabBarTheme: TabBarThemeData(
      // Dies entfernt die visuelle Linie des Indicators
      indicator: BoxDecoration(),
      // ... (andere Eigenschaften bleiben)
      labelColor: Colors.lightBlue,
    ),

    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: fontSizeBodyMedium,
        fontFamily: fontFamily,
      ),

      bodyLarge: TextStyle(fontSize: fontSizeBodyLarge, fontFamily: fontFamily),

      bodySmall: TextStyle(fontSize: fontSizeBodySmall, fontFamily: fontFamily),

      headlineLarge: TextStyle(
        fontSize: fontSizeHeadlineLarge,
        fontWeight: FontWeight.w600,
        color: textBar,
      ),

      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeHeadlineMedium,
        fontWeight: FontWeight.bold,
      ),

      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeHeadlineSmall,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
