import 'package:flutter/material.dart';

class BottombarElement extends StatelessWidget {
  const BottombarElement({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  final Widget icon;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navBarTheme = theme.navigationBarTheme;

    // Verwende den ?? Operator, um einen Standardwert bereitzustellen, falls null
    final textStyle =
        navBarTheme.labelTextStyle?.resolve({}) ??
        TextStyle(color: Colors.white);
    final iconstyle =
        navBarTheme.iconTheme?.resolve({}) ??
        IconThemeData(color: Colors.white);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconTheme(data: iconstyle, child: icon),
          SizedBox(height: 4),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}
