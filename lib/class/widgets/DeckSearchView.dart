// Erweiterte Deck-Suchansicht mit Archetyp-Dropdown
// Kann in search.dart oder meta.dart integriert werden

import 'package:flutter/material.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';

class DeckSearchView extends StatefulWidget {
  const DeckSearchView({super.key});

  @override
  State<DeckSearchView> createState() => _DeckSearchViewState();
}

class _DeckSearchViewState extends State<DeckSearchView> {
  final DeckSearchService _deckSearchService = DeckSearchService();
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _deckSearchFuture;
  Map<String, dynamic>? _selectedDeck;
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

    // Wenn Archetyp ausgewählt ist, suche danach
    // Wenn Text eingegeben wurde, suche danach
    // Sonst zeige neueste Decks
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

  @override
  Widget build(BuildContext context) {
    // Zeige DeckViewer wenn ein Deck ausgewählt wurde
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
        // Suchfeld
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Deck-Name oder Archetyp suchen...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _performSearch(),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Archetyp-Dropdown
        if (_isLoadingArchetypes)
          const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_availableArchetypes.isNotEmpty)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Oder Archetyp auswählen',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            value: _selectedArchetype,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Alle Archetypen'),
              ),
              ..._availableArchetypes.map(
                (archetype) => DropdownMenuItem<String>(
                  value: archetype,
                  child: Text(archetype),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedArchetype = value;
                // Wenn Archetyp ausgewählt wird, lösche Textsuche
                if (value != null) {
                  _searchController.clear();
                }
              });
            },
          ),

        const SizedBox(height: 16),

        // Such- und Reset-Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Suchen'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Zurücksetzen'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Suchergebnisse
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    if (_deckSearchFuture == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Suche nach Decks oder wähle einen Archetyp',
              style: Theme.of(context).textTheme.bodyLarge,
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler: ${snapshot.error}'),
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
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Keine Decks gefunden'),
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

            // Zähle Karten
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
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(
                  deckName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (archetype.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: archetype.split(',').map((arch) {
                            return Chip(
                              label: Text(
                                arch.trim(),
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Von: $username',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
}
