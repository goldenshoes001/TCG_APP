import 'package:flutter/material.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.texts, this.rating = "5/5"});

  final List<String> texts;
  final String rating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,

      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
    
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...texts.asMap().entries.map((entry) {
                    int index = entry.key;
                    String text = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        text,
                        style: index == 1
                            ? textTheme.bodyMedium
                            : textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
              ),
            ),
        
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 16),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    rating,
                    style: textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
