import 'package:flutter/material.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme(BuildContext context) {
  return ThemeData(
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
