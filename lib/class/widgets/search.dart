// search.dart - AKTUALISIERT MIT DECKVIEWER
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/search_results_view.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> with SingleTickerProviderStateMixin {
  final CardData _cardData = CardData();
  final DeckSearchService _deckSearchService = DeckSearchService();
  final TextEditingController suchfeld = TextEditingController();

  late TabController _tabController;

  Future<List<Map<String, dynamic>>>? _cardSearchFuture;
  Future<List<Map<String, dynamic>>>? _deckSearchFuture;
  Map<String, dynamic>? _selectedCard;
  Map<String, dynamic>? _selectedDeck;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    suchfeld.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      setState(() {
        _cardSearchFuture = Future.value([]);
        _deckSearchFuture = Future.value([]);
      });
      return;
    }

    if (_tabController.index == 0) {
      // Karten-Suche
      setState(() {
        _cardSearchFuture = _cardData.ergebniseAnzeigen(trimmedValue).then((
          list,
        ) async {
          final cards = list.cast<Map<String, dynamic>>();
          await _cardData.preloadCardImages(cards);
          return cards;
        });
        _selectedCard = null;
      });
    } else {
      // Deck-Suche
      setState(() {
        _deckSearchFuture = _deckSearchService.searchDecks(trimmedValue);
        _selectedDeck = null;
      });
    }
  }

  Widget _buildDeckResults() {
    if (_deckSearchFuture == null) {
      return Center(
        child: Text(
          'Gib einen Deck-Namen oder Archetyp ein',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _deckSearchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        final decks = snapshot.data ?? [];

        if (decks.isEmpty) {
          return const Center(child: Text('Keine Decks gefunden'));
        }

        return ListView.builder(
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final deckName = deck['deckName'] as String? ?? 'Unbekannt';
            final archetype = deck['archetype'] as String? ?? '';
            final username = deck['username'] as String? ?? 'Unbekannt';

            // Zähle Karten
            final mainDeck = deck['mainDeck'] as List<dynamic>? ?? [];
            final cardCount = mainDeck.fold(0, (sum, card) {
              if (card is Map<String, dynamic>) {
                return sum + (card['count'] as int? ?? 0);
              }
              return sum;
            });

            return Container(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(deckName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (archetype.isNotEmpty) Text('Archetypen: $archetype'),
                    Text('Von: $username'),
                    Text('$cardCount Karten'),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedDeck = deck;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCard != null) {
      return CardDetailView(
        cardData: _selectedCard!,
        onBack: () {
          setState(() {
            _selectedCard = null;
          });
        },
      );
    }

    // NEU: Verwende DeckViewer für gefundene Decks
    if (_selectedDeck != null) {
      return DeckViewer(
        deckData: _selectedDeck!,
        onBack: () {
          setState(() {
            _selectedDeck = null;
          });
        },
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Karten'),
            Tab(text: 'Decks'),
          ],
          onTap: (index) {
            setState(() {
              _cardSearchFuture = null;
              _deckSearchFuture = null;
              suchfeld.clear();
            });
          },
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 350),
                TextField(
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? "Karte suchen..."
                        : "Deck suchen...",
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
                  onSubmitted: _performSearch,
                  controller: suchfeld,
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 55),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      SearchResultsView(
                        searchFuture: _cardSearchFuture,
                        cardData: _cardData,
                        onCardSelected: (card) {
                          setState(() {
                            _selectedCard = card;
                          });
                        },
                      ),
                      _buildDeckResults(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
