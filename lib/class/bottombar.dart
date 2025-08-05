import 'package:flutter/material.dart';
import 'package:tcg_app/class/appdata.dart';
import 'package:tcg_app/class/bottombar_element.dart';

class Bottombar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) valueChanged;
  final List<NavigationDestination> navigationItems;
  final Color selectedIconColor;
  final double selectedIconSize;
  final Color unselectedIconColor;
  final double unselectedIconSize;
  final Color selectedLabelColor;
  final double selectedLabelSize;
  final Color unselectedLabelColor;
  final double unselectedLabelSize;

  const Bottombar({
    super.key,
    required this.currentIndex,
    required this.valueChanged,
    required this.navigationItems,
    this.selectedIconColor = Appdata.barColor,
    this.selectedIconSize = 25,
    this.selectedLabelColor = Appdata.textColor,
    this.selectedLabelSize = 14,
    this.unselectedIconColor = Colors.white,
    this.unselectedIconSize = 18,
    this.unselectedLabelColor = Colors.white,
    this.unselectedLabelSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Appdata.barColor,
      child: Container(
        width: double.infinity,
        height: 80,
        color: Appdata.barColor, // Die Farbe Ihrer Bottom Bar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(navigationItems.length, (index) {
            final bool isSelected = index == currentIndex;

            return Expanded(
              child: InkWell(
                onTap: () {
                  valueChanged(index);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.lightBlue : Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ), // Optional: Runde Ecken
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: BottombarElement(
                      icon: navigationItems[index].icon,
                      label: navigationItems[index].label,
                      isSelected: isSelected,
                      selectedIconColor: selectedIconColor,
                      unselectedIconColor: unselectedIconColor,
                      unselectedIconSize: unselectedIconSize,
                      selectedLabelColor: selectedLabelColor,
                      selectedLabelSize: selectedLabelSize,
                      unselectedLabelColor: unselectedLabelColor,
                      unselectedLabelSize: unselectedLabelSize,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
