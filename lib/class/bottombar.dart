import 'package:flutter/material.dart';

import 'package:tcg_app/class/bottombar_element.dart';
import 'package:tcg_app/theme/colors.dart';

class Bottombar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) valueChanged;
  final List<NavigationDestination> navigationItems;

  const Bottombar({
    super.key,
    required this.currentIndex,
    required this.valueChanged,
    required this.navigationItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: barColor,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.125,

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
