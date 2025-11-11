// operator_text_input.dart - Updated to DropdownMenu

import 'package:flutter/material.dart';

class OperatorTextInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String operator;
  final List<String> operators;
  final void Function(String?) onOperatorChanged;

  const OperatorTextInput({
    super.key,
    required this.label,
    required this.controller,
    required this.operator,
    required this.operators,
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
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
