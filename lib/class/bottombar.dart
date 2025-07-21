import 'package:flutter/material.dart';

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
  final Color indicatorColor;
  final Color backgroundColor;
  final Color surfaceTintColor;
  final double elevation;
  final Color shadowColor;


  const Bottombar({
    super.key,
    required this.currentIndex,
    required this.valueChanged,
    required this.navigationItems,
    this.selectedIconColor = Colors.white,
    this.selectedIconSize = 25,
    this.selectedLabelColor = Colors.white,
    this.selectedLabelSize = 14,
    this.unselectedIconColor = Colors.white,
    this.unselectedIconSize = 18,
    this.unselectedLabelColor = Colors.white,
    this.unselectedLabelSize = 14,
    this.indicatorColor = Colors.transparent,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
    this.shadowColor = Colors.transparent,
    this.surfaceTintColor = Colors.transparent,
  });

  
  IconThemeData get iconThemeSelectedData =>
      IconThemeData(color: selectedIconColor, size: selectedIconSize);

  IconThemeData get iconThemeUnSelectedData =>
      IconThemeData(color: unselectedIconColor, size: unselectedIconSize);

  TextStyle get textSelected => TextStyle(
    color: selectedLabelColor,
    fontFamily: "Arial",
    fontSize: selectedLabelSize,
  );

  TextStyle get textUnSelected => TextStyle(
    color: unselectedLabelColor,
    fontFamily: "Arial",
    fontSize: unselectedLabelSize,
  );

  TextStyle _getLabelTextStyle(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return textSelected;
    }
    return textUnSelected;
  }

  IconThemeData _getIconThemeData(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return iconThemeSelectedData;
    }
    return iconThemeUnSelectedData;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        navigationBarTheme: NavigationBarThemeData(
          // Hier die Funktionen verwenden
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            _getLabelTextStyle,
          ),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            _getIconThemeData,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: valueChanged,
        destinations: navigationItems,
        indicatorColor: indicatorColor,
        backgroundColor: backgroundColor,
        surfaceTintColor: surfaceTintColor,
        elevation: elevation,
        shadowColor: shadowColor,
      ),
    );
  }
}
