import 'package:flutter/material.dart';
import 'package:tcg_app/theme/colors_lighttheme.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.texts, this.rating = "5/5"});

  final List<String> texts;

  final String rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            SizedBox(height: 20),
            Card(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            itemCount: texts.length,

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  mainAxisSpacing: 0.2,
                                  childAspectRatio: 10,
                                ),
                            itemBuilder: (context, index) {
                              return Text(
                                texts[index],
                                style: index == 1
                                    ? theme.bodyMedium
                                    : theme.bodyLarge,
                              );
                            },
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.yellow),
                              SizedBox(width: 5),
                              Text(rating),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
