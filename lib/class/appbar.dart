import 'package:flutter/material.dart';
import 'package:tcg_app/theme/sizing.dart';

class Barwidget extends StatelessWidget {
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
          ClipRRect(
            child: Image.asset(
              'assets/icon/appicon.png',

              height: 15,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * widthSizedBoxAppBar,
          ),
          Text(title),
        ],
      ),
    );
  }
}
