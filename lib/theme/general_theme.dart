import 'package:flutter/material.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme() {
  return ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: fontSizeBody,
        fontFamily: fontFamily,
      ),

      headlineLarge: TextStyle(
        fontSize: appbarTextSize,
        fontWeight: FontWeight.bold,
        color: textBar,
      ),
    ),
  );
}
