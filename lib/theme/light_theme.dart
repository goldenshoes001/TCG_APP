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
    height: MediaQuery.sizeOf(context).height * bottombarSize,

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
    bodyLarge: generalTheme().textTheme.bodyLarge!.copyWith(
      color: colorBodyLarge,
    ),
    bodyMedium: generalTheme().textTheme.bodyMedium!.copyWith(
      color: bodyMediumColor,
    ),
    bodySmall: generalTheme().textTheme.bodySmall!.copyWith(
      color: colorBodySmall,
    ),
    headlineLarge: generalTheme().textTheme.headlineLarge!.copyWith(
      color: colorHeadlineLarge,
    ),

    headlineMedium: generalTheme().textTheme.headlineMedium!.copyWith(
      color: colorHeadlineMedium,
    ),
    headlineSmall: generalTheme().textTheme.headlineSmall!.copyWith(
      color: colorHeadlineSmall,
    ),
  ),
);
