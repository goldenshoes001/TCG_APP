import 'package:flutter/material.dart';

import 'colors.dart';
import 'textstyle.dart';

ThemeData generalTheme() {
  return ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: fontSizeBody,
        fontFamily: fontFamily,
      ),

      headlineLarge: TextStyle(
        fontSize: appbarTextSize,
        fontWeight: FontWeight.bold,
        color: startBarcolor.onPrimary,
      ),
    ),
  );
}
