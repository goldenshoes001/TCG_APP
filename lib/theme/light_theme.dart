import 'package:flutter/material.dart';
import 'package:tcg_app/theme/general_theme.dart';
import 'package:tcg_app/theme/colors_lighttheme.dart';
import 'package:tcg_app/theme/sizing.dart';
import "package:tcg_app/theme/textstyle.dart";

ThemeData lightTheme(BuildContext context) => generalTheme().copyWith(
  scaffoldBackgroundColor: bodyColor,
  appBarTheme: AppBarTheme(
    backgroundColor: barColor,
    titleTextStyle: TextStyle(
      color: textBar,
      fontSize: appbarTextSize,
      fontWeight: fontWeightAppbar,
    ),
    toolbarHeight: MediaQuery.sizeOf(context).height * 0.08,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: barColor,
    height: MediaQuery.sizeOf(context).height * 0.12,

    // Icons immer gleich
    iconTheme: WidgetStateProperty.all(
      IconThemeData(
        color: iconColor, // Immer die gleiche Farbe
        size: sizeIcons,
      ),
    ),

    // Labels auch immer gleich
    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        color: labelcolor, // Immer die gleiche Farbe
        fontFamily: fontFamily,
        fontSize: sizeLabels,
        fontWeight: FontWeight.normal,
      ),
    ),
  ),
  textTheme: generalTheme().textTheme.copyWith(
    bodyMedium: generalTheme().textTheme.bodyMedium!.copyWith(color: textColor),
  ),
);
