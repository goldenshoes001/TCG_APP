// card_search_dialog.dart - Dialog zur Kartensuche beim Deck-Erstellen
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class CardSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic> card, int count) onCardSelected;
  final bool isSideDeck;

  const CardSearchDialog({
    super.key,
    required this.onCardSelected,
    this.isSideDeck = false,
  });

  @override
  State<CardSearchDialog> createState() => _CardSearchDialogState();
}

class _CardSearchDialogState extends State<CardSearchDialog> {
  final CardData _cardData = CardData();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _searchFuture;
  Map<String, dynamic>? _selectedCard;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final trimmedValue = query.trim();
    if (trimmedValue.isNotEmpty) {
      setState(() {
        _searchFuture = _cardData.ergebniseAnzeigen(trimmedValue).then((
          list,
        ) async {
          final cards = list.cast<Map<String, dynamic>>();
          // Filter: token und skill Karten ausschließen
          final filteredCards = cards.where((card) {
            final frameType = (card['frameType'] as String? ?? '')
                .toLowerCase();
            return frameType != 'token' && frameType != 'skill';
          }).toList();
          await _cardData.preloadCardImages(filteredCards);
          return filteredCards;
        });
      });
    } else {
      setState(() {
        _searchFuture = Future.value([]);
      });
    }
  }

  int _getMaxAllowedCount(Map<String, dynamic> card) {
    final banlistInfo = card['banlist_info'];
    if (banlistInfo == null) return 3;

    final tcgBan = banlistInfo['ban_tcg'] as String?;

    if (tcgBan == 'Forbidden') return 0;
    if (tcgBan == 'Limited') return 1;
    if (tcgBan == 'Semi-Limited') return 2;

    return 3;
  }

  void _showCardCountDialog(Map<String, dynamic> card) {
    final maxCount = _getMaxAllowedCount(card);

    if (maxCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card['name']} ist verboten und kann nicht hinzugefügt werden.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Wie oft hinzufügen?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card['name'] ?? 'Unbekannte Karte'),
              const SizedBox(height: 16),
              if (maxCount < 3)
                Text(
                  'Diese Karte ist ${maxCount == 1 ? 'limitiert' : 'semi-limitiert'}',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ...List.generate(maxCount, (index) {
              final count = index + 1;
              return TextButton(
                onPressed: () {
                  widget.onCardSelected(card, count);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text('$count${count == 1 ? 'x' : 'x'}'),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Karte suchen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Kartenname eingeben...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchFuture == null
                  ? Center(
                      child: Text(
                        'Gib einen Kartennamen ein, um zu suchen',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future: _searchFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Fehler: ${snapshot.error}'),
                          );
                        }

                        final cards = snapshot.data ?? [];

                        if (cards.isEmpty) {
                          return const Center(
                            child: Text('Keine Karten gefunden'),
                          );
                        }

                        return ListView.builder(
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            final cardImages =
                                card['card_images'] as List<dynamic>?;
                            final imageUrl =
                                cardImages != null && cardImages.isNotEmpty
                                ? (cardImages[0]
                                          as Map<
                                            String,
                                            dynamic
                                          >)['image_url_cropped'] ??
                                      ''
                                : '';

                            return Card(
                              child: ListTile(
                                leading: imageUrl.isNotEmpty
                                    ? FutureBuilder<String>(
                                        future: _cardData.getImgPath(imageUrl),
                                        builder: (context, imgSnapshot) {
                                          if (imgSnapshot.hasData &&
                                              imgSnapshot.data!.isNotEmpty) {
                                            return Image.network(
                                              imgSnapshot.data!,
                                              width: 40,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return const Icon(Icons.image);
                                        },
                                      )
                                    : const Icon(Icons.image),
                                title: Text(card['name'] ?? 'Unbekannt'),
                                subtitle: Text(card['type'] ?? ''),
                                onTap: () => _showCardCountDialog(card),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
