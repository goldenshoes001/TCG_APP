// search.dart - AKTUALISIERT MIT DECKVIEWER
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/DeckSearchView.dart';
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
      // ACHTUNG: Die globale Suche wird im Deck-Tab nicht mehr unterstützt.
      // Wenn der Benutzer hier tippt, löst er versehentlich die Suche aus.
      // Da wir das Suchfeld nun ausblenden, ist dieser else-Block obsolet,
      // aber wir lassen die Logik hier zur Sicherheit.
      setState(() {
        _deckSearchFuture = _deckSearchService.searchDecks(trimmedValue);
        _selectedDeck = null;
      });
    }
  }

 @override
  Widget build(BuildContext context) {
    // ✅ WENN Karten-Detail: Zeige NUR CardDetailView
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

    // ✅ WENN Deck-Detail: Zeige NUR DeckViewer (OHNE Tabs!)
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

    // ✅ SONST: Zeige normale Ansicht MIT Tabs
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

                if (_tabController.index == 0)
                  Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: "Karte suchen...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        onSubmitted: _performSearch,
                        controller: suchfeld,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 55),
                    ],
                  ),

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
                      const DeckSearchView(),
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
