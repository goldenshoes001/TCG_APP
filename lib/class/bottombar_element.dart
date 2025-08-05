import 'package:flutter/material.dart';
import 'package:tcg_app/class/appdata.dart';

class BottombarElement extends StatelessWidget {
  const BottombarElement({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.selectedIconColor = Appdata.textColor,
    this.selectedIconSize = 25,
    this.unselectedIconColor = Colors.white,
    this.unselectedIconSize = 18,
    this.selectedLabelColor = Appdata.textColor,
    this.selectedLabelSize = 14,
    this.unselectedLabelColor = Colors.white,
    this.unselectedLabelSize = 14,
  });

  final Widget icon;
  final String label;
  final bool isSelected;
  final Color selectedIconColor;
  final double selectedIconSize;
  final Color unselectedIconColor;
  final double unselectedIconSize;
  final Color selectedLabelColor;
  final double selectedLabelSize;
  final Color unselectedLabelColor;
  final double unselectedLabelSize;

  @override
  Widget build(BuildContext context) {
    // Auswahl der richtigen Farben und Größen basierend auf dem isSelected-Status
    final Color iconColor = isSelected
        ? selectedIconColor
        : unselectedIconColor;
    final double iconSize = isSelected ? selectedIconSize : unselectedIconSize;
    final Color labelColor = isSelected
        ? selectedLabelColor
        : unselectedLabelColor;
    final double labelSize = isSelected
        ? selectedLabelSize
        : unselectedLabelSize;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.start, // Zentriert die Elemente vertikal

        children: [
          IconTheme(
            data: IconThemeData(color: iconColor, size: iconSize),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontFamily: "Arial",
              fontSize: labelSize,
            ),
          ),
        ],
      ),
    );
  }
}
