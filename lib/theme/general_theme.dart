import 'package:flutter/material.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme(BuildContext context) {
  return ThemeData(
    cardTheme: CardThemeData(
      margin: EdgeInsets.all(5),
      color: Colors.transparent,
      elevation: 0,
    ),
    tabBarTheme: TabBarThemeData(
      // ✅ KORRIGIERT: Entfernt den Unterstrich komplett
      indicator: const BoxDecoration(color: Colors.transparent),
      dividerColor: Colors.transparent, // ✅ NEU: Entfernt die Trennlinie
      labelColor: Colors.lightBlue,
      unselectedLabelColor: Colors.grey,
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

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  );
}
