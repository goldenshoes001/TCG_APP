import 'package:flutter/material.dart';
import 'package:tcg_app/class/common/bottombar_element.dart';

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
    final theme = Theme.of(context);
    final navBarTheme = theme.navigationBarTheme;

    final backgroundColor = navBarTheme.backgroundColor;
    final containerHeight = navBarTheme.height;

    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: containerHeight,
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
                  color: isSelected
                      ? navBarTheme.indicatorColor ?? Colors.lightBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
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
    );
  }
}
