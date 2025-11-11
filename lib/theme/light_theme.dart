import 'package:flutter/material.dart';
import 'package:tcg_app/theme/general_theme.dart';
import 'package:tcg_app/theme/colors_lighttheme.dart';
import 'package:tcg_app/theme/sizing.dart';
import "package:tcg_app/theme/textstyle.dart";

extension MyLightThemeDataExtension on ThemeData {
  Color get darkColorOfContainer => containerColor;
}

ThemeData lightTheme(BuildContext context) => generalTheme(context).copyWith(
  brightness: Brightness.light,
  cardColor: cardColor,
  scaffoldBackgroundColor: bodyColor,
  canvasColor: cardColor,

  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,

      labelStyle: TextStyle(color: inputField),
      hintStyle: TextStyle(color: inputField),
    ),

    textStyle: TextStyle(
      color: Colors.lightBlue,
      fontFamily: fontFamily,
      fontSize: 14,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: labelcolor,
      backgroundColor: cardColor,

      textStyle: Theme.of(context).textTheme.bodyLarge,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: labelcolor,
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
    labelStyle: TextStyle(color: inputField, fontFamily: fontFamily),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0), // ← AUF 0 ÄNDERN
      borderSide: BorderSide(color: inputField),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0), // ← AUF 0 ÄNDERN
      borderSide: BorderSide(color: inputField, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0), // ← BLEIBT 0
      borderSide: BorderSide(color: cardColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(0), // ← BLEIBT 0
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
    toolbarHeight: MediaQuery.sizeOf(context).height * appbarSize,
    iconTheme: IconThemeData(color: Colors.white),
  ),

  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: barColor,
    height: MediaQuery.sizeOf(context).height * bottombarSize,

    iconTheme: WidgetStateProperty.all(
      IconThemeData(color: iconColor, size: sizeIcons),
    ),

    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        color: textColor,
        fontFamily: fontFamily,
        fontSize: sizeLabels,
        fontWeight: FontWeight.normal,
      ),
    ),
  ),

  iconTheme: IconThemeData(color: listTileIconColor),

  listTileTheme: ListTileThemeData(
    textColor: listTileTextColor,
    iconColor: listTileIconColor,
    titleTextStyle: TextStyle(color: listTileTextColor),
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
    ).textTheme.headlineMedium!.copyWith(color: colorHeadlineLarge),
    headlineSmall: generalTheme(
      context,
    ).textTheme.headlineSmall!.copyWith(color: colorHeadlineSmall),

    titleMedium: TextStyle(
      color: listTileTextColor,
      fontFamily: fontFamily,
      fontSize: 12,
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: listTileTextColor,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  ),

  dialogTheme: DialogThemeData(backgroundColor: cardColor),
);
