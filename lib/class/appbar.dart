import 'package:flutter/material.dart';

class Barwidget extends StatelessWidget implements PreferredSizeWidget {
  final MainAxisAlignment titleFlow;
  final Color barColor;
  final String title;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;
  final int elevation;
  final Color shadow;
  final Color surfaceTintColor;
  final double height;
  const Barwidget({
    super.key,
    this.titleFlow = MainAxisAlignment.center,
    this.barColor = Colors.black,
    this.title = "Platzhalter",
    this.fontSize = 24,
    this.textColor = const Color(0xFF456585),
    this.fontWeight = FontWeight.normal,
    this.elevation = 0,
    this.shadow = Colors.transparent,
    this.surfaceTintColor = Colors.transparent,
    this.height = 40,
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: barColor,
      centerTitle: false,
      title: Row(
        mainAxisAlignment: titleFlow,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
      elevation: 0,
      shadowColor: shadow,
      surfaceTintColor: surfaceTintColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
