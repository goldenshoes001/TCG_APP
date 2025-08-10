import 'package:flutter/material.dart';
import 'package:tcg_app/theme/colors_lighttheme.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.texts, this.rating = "5/5"});

  final List<String> texts;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...texts.asMap().entries.map((entry) {
                    int index = entry.key;
                    String text = entry.value;
                    return Text(
                      text,
                      style: index == 1 ? theme.bodyMedium : theme.bodyLarge,
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow),
                      const SizedBox(width: 5),
                      Text(rating),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
