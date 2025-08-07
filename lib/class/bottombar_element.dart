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
    // Auswahl der richtigen Farben und Größen basierend auf dem isSelected-Status

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.start, // Zentriert die Elemente vertikal

        children: [icon, const SizedBox(height: 4), Text(label)],
      ),
    );
  }
}
