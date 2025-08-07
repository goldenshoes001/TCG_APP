import 'package:flutter/material.dart';
import 'package:tcg_app/theme/general_theme.dart';
import 'package:tcg_app/theme/colors.dart';
import 'package:tcg_app/theme/sizing.dart';
import "package:tcg_app/theme/textstyle.dart";

ThemeData darkTheme = generalTheme().copyWith(
  appBarTheme: AppBarTheme(
    color: barColor, // Background color for the AppBar in light mode
    titleTextStyle: TextStyle(
      color: textBar, // AppBar title text color for light mode
      fontSize: appbarTextSize,
      fontWeight: fontWeightAppbar,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: barColor,
    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        color: labelcolor,
        fontFamily: fontFamily,
        fontSize: sizeLabels,
      ),
    ),
  ),
);
