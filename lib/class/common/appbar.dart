import 'package:flutter/material.dart';
import 'package:tcg_app/class/savedata.dart';
import 'package:tcg_app/theme/sizing.dart';

class Barwidget extends StatefulWidget {
  final MainAxisAlignment titleFlow;
  final String title;
  bool darkMode;

  Barwidget({
    super.key,
    this.titleFlow = MainAxisAlignment.center,
    this.title = "",
    required this.darkMode,
  });

  @override
  State<Barwidget> createState() => _BarwidgetState();
}

class _BarwidgetState extends State<Barwidget> {
  SaveData data = SaveData();
  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      actions: [
        Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
        Switch(
          value: widget.darkMode,
          onChanged: (newValue) {
            setState(() {
              widget.darkMode = newValue;
            });

            data.saveBool("darkMode", newValue);
          },
        ),
      ],
      title: Row(
        mainAxisAlignment: widget.titleFlow,
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
          Text(widget.title),
        ],
      ),
    );
  }
}
