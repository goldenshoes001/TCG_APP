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

    // Den TextStyle aus dem NavigationBarTheme holen
    final textStyle = navBarTheme.labelTextStyle!.resolve({});
    final iconstyle = navBarTheme.iconTheme!.resolve({})!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconTheme(data: iconstyle, child: icon),
          SizedBox(height: 4),
          Text(label, style: textStyle), // Jetzt ist textStyle definiert
        ],
      ),
    );
  }
}
