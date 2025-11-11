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
  scaffoldBackgroundColor: cardColor,
  canvasColor: cardColor,

  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      labelStyle: TextStyle(color: inputField),
      hintStyle: TextStyle(color: inputField),
    ),

    // ✅ TEXT-STYLE FÜR DEN AUSGEWÄHLTEN TEXT IM INPUT-FELD
    textStyle: TextStyle(
      color: Colors.lightBlue,
      fontFamily: fontFamily,
      fontSize: 14,
    ),

    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(cardColor),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),

      // ✅ BREITE DER DROPDOWN-LISTE
      fixedSize: WidgetStateProperty.all(
        Size(
          MediaQuery.of(context).size.height,
          MediaQuery.of(context).size.width,
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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

  menuButtonTheme: MenuButtonThemeData(
    style: ButtonStyle(
      // 1. Textfarbe (Foreground Color) ändern
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        // Beispiel: Standard-Textfarbe ist lila
        return Colors.black;
      }),

      // 2. Hintergrundfarbe beim Hovern/Fokussieren (Background Color) ändern

      // Transparente Standard-Hintergrundfarbe (oder null, um das MenuStyle zu verwenden)

      // 3. Textstil direkt anpassen (z.B. Schriftgröße)
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16)),
    ),
  ),
);
