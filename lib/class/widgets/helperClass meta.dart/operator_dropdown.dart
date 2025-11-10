// operator_dropdown.dart

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
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            initialValue: operator,
            items: operators.map((op) {
              return DropdownMenuItem<String>(
                value: op,
                child: Text(op, textAlign: TextAlign.center),
              );
            }).toList(),
            onChanged: onOperatorChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            initialValue: value,
            items: [
              DropdownMenuItem<String>(value: null, child: Text(label)),
              ...items.map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
