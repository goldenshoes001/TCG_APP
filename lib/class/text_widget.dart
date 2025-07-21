import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final String fontFamily;
  final TextAlign textAlign;
  final TextOverflow textOverflow;
  final int? maxlines;
  final bool softwrap;

  const TextWidget({
    super.key,
    this.text = "",
    this.fontSize = 70,
    this.color = Colors.white,
    this.fontWeight = FontWeight.normal,
    this.fontFamily = "arial",
    this.maxlines,
    this.textAlign = TextAlign.center,
    this.textOverflow = TextOverflow.clip,
    this.softwrap = true,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        textAlign: textAlign,
        overflow: textOverflow,
        softWrap: true,
        maxLines: maxlines,
        text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
