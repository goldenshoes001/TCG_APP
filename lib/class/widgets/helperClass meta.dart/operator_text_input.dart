// operator_text_input.dart

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
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            value: operator,
            items: operators.map((op) {
              return DropdownMenuItem<String>(
                value: op,
                child: Text(op, textAlign: TextAlign.center),
              );
            }).toList(),
            onChanged: onOperatorChanged,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.bodyMedium,
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
