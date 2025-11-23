// operator_dropdown.dart - Updated to DropdownMenu

import 'package:flutter/material.dart';

class OperatorDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String operator;
  final List<String> operators;
  final void Function(String?) onChanged;
  final void Function(String?) onOperatorChanged;

  const OperatorDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.operator,
    required this.operators,
    required this.onChanged,
    required this.onOperatorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownMenu<String>(
            initialSelection: operator,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: operators.map((op) {
              return DropdownMenuEntry<String>(value: op, label: op);
            }).toList(),
            onSelected: onOperatorChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownMenu<String>(
            label: Text(label),
            initialSelection: value,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: items.map((item) {
              return DropdownMenuEntry<String>(value: item, label: item);
            }).toList(),
            onSelected: onChanged,
          ),
        ),
      ],
    );
  }
}
