import 'package:flutter/material.dart';
import 'package:tcg_app/theme/general_theme.dart';
import 'package:tcg_app/theme/colors_lighttheme.dart';
import 'package:tcg_app/theme/sizing.dart';
import "package:tcg_app/theme/textstyle.dart";

extension MyLightThemeDataExtension on ThemeData {
  Color get lightColorOfContainer => containerColor;
}

ThemeData lightTheme(BuildContext context) => generalTheme(context).copyWith(
  brightness: Brightness.light,
  cardColor: cardColor,
  scaffoldBackgroundColor: bodyColor,

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.grey,
      backgroundColor: cardColor,
      side: BorderSide(color: cardColor, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: Theme.of(context).textTheme.bodyLarge,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardColor,
    hintStyle: TextStyle(color: inputField),
    prefixIconColor: inputField,
    suffixIconColor: inputField,
    hoverColor: inputField,

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: inputField),
    ),

    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: inputField, width: 2.0),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: cardColor),
    ),

    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: errorColor),
    ),
  ),
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

    iconTheme: WidgetStateProperty.all(
      IconThemeData(color: iconColor, size: sizeIcons),
    ),

    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        color: labelcolor,
        fontFamily: fontFamily,
        fontSize: sizeLabels,
        fontWeight: FontWeight.normal,
      ),
    ),
  ),
  textTheme: generalTheme(context).textTheme.copyWith(
    bodyLarge: generalTheme(
      context,
    ).textTheme.bodyLarge!.copyWith(color: colorBodyLarge),
    bodyMedium: generalTheme(
      context,
    ).textTheme.bodyMedium!.copyWith(color: bodyMediumColor),
    bodySmall: generalTheme(
      context,
    ).textTheme.bodySmall!.copyWith(color: colorBodySmall),
    headlineLarge: generalTheme(
      context,
    ).textTheme.headlineLarge!.copyWith(color: colorHeadlineLarge),

    headlineMedium: generalTheme(
      context,
    ).textTheme.headlineMedium!.copyWith(color: colorHeadlineMedium),
    headlineSmall: generalTheme(
      context,
    ).textTheme.headlineSmall!.copyWith(color: colorHeadlineSmall),
  ),
);
