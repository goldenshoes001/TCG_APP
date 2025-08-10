import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'colors_darktheme.dart';
import 'textstyle.dart';

ThemeData generalTheme(BuildContext context) {
  return ThemeData(
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: fontSizeBodyMedium.sp,
        fontFamily: fontFamily,
      ),

      bodyLarge: TextStyle(
        fontSize: fontSizeBodyLarge.sp,
        fontFamily: fontFamily,
      ),

      bodySmall: TextStyle(
        fontSize: fontSizeBodySmall.sp,
        fontFamily: fontFamily,
      ),

      headlineLarge: TextStyle(
        fontSize: fontSizeHeadlineLarge.sp,
        fontWeight: FontWeight.w600,
        color: textBar,
      ),

      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeHeadlineMedium.sp,
      ),

      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeHeadlineSmall.sp,
      ),
    ),
  );
}
