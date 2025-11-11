// DeckSearchView.dart - KOMPAKTE VERSION MIT MEHR PLATZ FÜR DECKS
import 'package:flutter/material.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class DeckSearchView extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDeckSelected;
  const DeckSearchView({super.key, this.onDeckSelected});

  @override
  State<DeckSearchView> createState() => _DeckSearchViewState();
}

class _DeckSearchViewState extends State<DeckSearchView> {
  final DeckSearchService _deckSearchService = DeckSearchService();
  final CardData _cardData = CardData();
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _deckSearchFuture;

  List<String> _availableArchetypes = [];
  String? _selectedArchetype;
  bool _isLoadingArchetypes = true;

  @override
  void initState() {
    super.initState();
    _loadArchetypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchetypes() async {
    setState(() => _isLoadingArchetypes = true);

    try {
      final archetypes = await _deckSearchService.getAllArchetypes();
      if (mounted) {
        setState(() {
          _availableArchetypes = archetypes;
          _isLoadingArchetypes = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Archetypen: $e');
      if (mounted) {
        setState(() => _isLoadingArchetypes = false);
      }
    }
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    final selectedArchetype = _selectedArchetype;

    if (selectedArchetype != null && selectedArchetype.isNotEmpty) {
      setState(() {
        _deckSearchFuture = _deckSearchService.searchDecks(selectedArchetype);
      });
    } else if (searchTerm.isNotEmpty) {
      setState(() {
        _deckSearchFuture = _deckSearchService.searchDecks(searchTerm);
      });
    } else {
      setState(() {
        _deckSearchFuture = _deckSearchService.getRecentDecks();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedArchetype = null;
      _deckSearchFuture = null;
    });
  }

  Widget _buildDeckCoverImage(Map<String, dynamic> deck) {
    final coverImageUrl = deck['coverImageUrl'] as String?;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(),
      child: ClipOval(
        child: coverImageUrl == null || coverImageUrl.isEmpty
            ? Container(
                color: Colors.grey[200],
                child: const Icon(Icons.style, size: 20, color: Colors.grey),
              )
            : FutureBuilder<String>(
                future: _cardData.getImgPath(coverImageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 20,
                        color: Colors.grey,
                      ),
                    );
                  }

                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          size: 20,
                          color: Colors.grey,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Kompakter Suchbereich in einer Zeile
          Row(
            children: [
              // TextField für Deckname-Suche
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by Deckname",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),

              const SizedBox(width: 8),

              // Search Icon Button
              IconButton(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Suchen',
              ),

              const SizedBox(width: 4),

              // Reset Icon Button
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Zurücksetzen',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dropdown für Archetypen
          if (_isLoadingArchetypes)
            const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableArchetypes.isNotEmpty)
            DropdownMenu<String?>(
              initialSelection: _selectedArchetype,
              leadingIcon: const Icon(Icons.category, size: 18),
              label: const Text('Archetype'),
              width: MediaQuery.of(context).size.width - 24,
              menuHeight: 300,
              onSelected: (String? value) {
                setState(() {
                  _selectedArchetype = value;
                  if (value != null) {
                    _searchController.clear();
                    _performSearch();
                  }
                });
              },
              dropdownMenuEntries: [
                const DropdownMenuEntry<String?>(
                  value: null,
                  label: 'All Archetypes',
                ),
                ..._availableArchetypes.map(
                  (archetype) => DropdownMenuEntry<String>(
                    value: archetype,
                    label: archetype,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Erweiterter Bereich für Ergebnisse
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_deckSearchFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Suche nach Decks oder wähle einen Archetyp',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Fehler: ${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final decks = snapshot.data ?? [];

        if (decks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Keine Decks gefunden',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final deckName = deck['deckName'] as String? ?? 'Unbekannt';
            final archetype = deck['archetype'] as String? ?? '';
            final username = deck['username'] as String? ?? 'Unbekannt';

            final mainDeck = deck['mainDeck'] as List<dynamic>? ?? [];
            final extraDeck = deck['extraDeck'] as List<dynamic>? ?? [];
            final sideDeck = deck['sideDeck'] as List<dynamic>? ?? [];

            final mainCount = mainDeck.fold<int>(0, (sum, card) {
              if (card is Map<String, dynamic>) {
                return sum + (card['count'] as int? ?? 0);
              }
              return sum;
            });

            final extraCount = extraDeck.fold<int>(0, (sum, card) {
              if (card is Map<String, dynamic>) {
                return sum + (card['count'] as int? ?? 0);
              }
              return sum;
            });

            final sideCount = sideDeck.fold<int>(0, (sum, card) {
              if (card is Map<String, dynamic>) {
                return sum + (card['count'] as int? ?? 0);
              }
              return sum;
            });

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              child: ListTile(
                leading: _buildDeckCoverImage(deck),
                title: Text(
                  deckName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Von: $username'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Main: $mainCount | Extra: $extraCount | Side: $sideCount',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  widget.onDeckSelected?.call(deck);
                },
              ),
            );
          },
        );
      },
    );
  }
}
