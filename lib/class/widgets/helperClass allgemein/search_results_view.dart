// search_results_view.dart - MIT RIVERPOD
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/card_list_item.dart';

class SearchResultsView extends ConsumerWidget {
  final Future<List<Map<String, dynamic>>>? searchFuture;
  final Function(Map<String, dynamic> card) onCardSelected;

  const SearchResultsView({
    super.key,
    required this.searchFuture,
    required this.onCardSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: searchFuture,
      builder: (context, snapshot) {
        if (searchFuture == null) {
          return const Center(child: Text('Enter a keyword.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('loading...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error on loading: ${snapshot.error}'));
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return const Center(
            child: Text('No Cards found.', textAlign: TextAlign.center),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cards.length} Card(s) found'),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return CardListItem(
                    card: card,
                    onTap: () => onCardSelected(card),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
