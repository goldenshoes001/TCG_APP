import 'package:flutter/material.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme() {
  return ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: fontSizeBodyMedium,
        fontFamily: fontFamily,
      ),

      bodyLarge: TextStyle(
        fontSize: fontSizeBodyLarge + 2,
        fontFamily: fontFamily,
      ),

      bodySmall: TextStyle(fontSize: fontSizeBodySmall, fontFamily: fontFamily),

      headlineLarge: TextStyle(
        fontSize: fontSizeHeadlineLarge,
        fontWeight: FontWeight.w600,
        color: textBar,
      ),

      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeheadlineMedium,
      ),

      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeHeadlineSmall,
      ),
      labelLarge: TextStyle(),
      labelMedium: TextStyle(),
      labelSmall: TextStyle(),

      titleLarge: TextStyle(),
      titleMedium: TextStyle(),
      titleSmall: TextStyle(),
    ),
  );
}
