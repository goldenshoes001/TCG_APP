// filter_dropdown.dart - Updated to DropdownMenu

import 'package:flutter/material.dart';

class FilterDropdown extends StatelessWidget {

  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const FilterDropdown({
    super.key,

    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(

      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: items.map((item) {
        return DropdownMenuEntry<String>(value: item, label: item);
      }).toList(),
      onSelected: onChanged,
    );
  }
}
