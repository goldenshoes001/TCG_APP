import 'package:flutter/material.dart';
import 'package:tcg_app/theme/general_theme.dart';
import 'package:tcg_app/theme/colors_darktheme.dart';
import 'package:tcg_app/theme/sizing.dart';
import "package:tcg_app/theme/textstyle.dart";

extension MyDarkThemeDataExtension on ThemeData {
  Color get darkColorOfContainer => containerColor;
}

ThemeData darkTheme(BuildContext context) => generalTheme(context).copyWith(
  brightness: Brightness.dark,
  cardColor: cardColor,
  scaffoldBackgroundColor: bodyColor,
  canvasColor: cardColor,

  dropdownMenuTheme: DropdownMenuThemeData(
    
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Colors.red),
      ),
    ),

    textStyle: TextStyle(
      fontFamily: "arial",
      fontSize: 14,
      color: Colors.lightBlue,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: labelcolor,
      backgroundColor: cardColor,
      side: BorderSide(color: cardColor, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    labelStyle: TextStyle(
      color: inputField,
      fontFamily: fontFamily,
      // Passen Sie die Schriftgröße bei Bedarf an
    ),
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

  iconTheme: IconThemeData(color: iconColor),

  listTileTheme: const ListTileThemeData(
    // Farbe für den gesamten ListTile-Inhalt (Titel, Untertitel, Icons)
    textColor: Colors.white,
    iconColor: Colors.white70,

    // Die beste Methode: Den Stil für den Titel direkt festlegen.
    titleTextStyle: TextStyle(
      color: Colors.white,
      // Optional: Weitere Anpassungen basierend auf Ihrem bodyLarge
      // fontSize: 16,
      // fontWeight: FontWeight.w500,
    ),
  ), // <--- FEHLENDE KLAMMER UND KOMMA HINZUGEFÜGT

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
      color: Colors.white,
      fontFamily: fontFamily,
      fontSize: 12, // Oder deine gewünschte Größe
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white, // Textfarbe aller TextButtons
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  ),

  dialogTheme: DialogThemeData(backgroundColor: cardColor),

  cardTheme: CardThemeData(color: Colors.transparent),
);
