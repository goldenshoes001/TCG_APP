import 'package:flutter/material.dart';
import 'package:tcg_app/theme/sizing.dart';

class Barwidget extends StatelessWidget implements PreferredSizeWidget {
  final MainAxisAlignment titleFlow;
  final String title;

  const Barwidget({
    super.key,
    this.titleFlow = MainAxisAlignment.center,
    this.title = "",
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      // toolbarHeight wird automatisch aus dem Theme genommen!
      title: Row(
        mainAxisAlignment: titleFlow,
        children: [
          Image(
            image: AssetImage("assets/icon/appicon.png"),
            height: appbarIconSize,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * widthSizedBoxAppBar,
          ),
          Text(title),
        ],
      ),
    );
  }

  @override
  Size get preferredSize {
    // Diese Methode wird für das Scaffold Layout verwendet
    return Size.fromHeight(
      kToolbarHeight,
    ); // Standard, wird von Theme überschrieben
  }
}
