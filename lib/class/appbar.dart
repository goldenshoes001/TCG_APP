import 'package:flutter/material.dart';
import 'package:tcg_app/class/appdata.dart';

class Barwidget extends StatelessWidget implements PreferredSizeWidget {
  final Color barColor;
  final String title;
  final int elevation;
  final Color shadow;
  final Color surfaceTintColor;
  const Barwidget({
    super.key,
    this.barColor = Colors.black,
    this.title = "",
    this.elevation = 0,
    this.shadow = Colors.transparent,
    this.surfaceTintColor = Colors.transparent,
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: barColor,
      title: Text(title),
      elevation: 0,
      shadowColor: shadow,
      surfaceTintColor: surfaceTintColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(Appdata.appbarSize);
}
