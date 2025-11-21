// DeckSearchView.dart - VOLLSTÄNDIG KORRIGIERTE VERSION
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/providers/app_providers.dart';

class DeckSearchView extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onDeckSelected;
  const DeckSearchView({super.key, this.onDeckSelected});

  @override
  ConsumerState<DeckSearchView> createState() => _DeckSearchViewState();
}

class _DeckSearchViewState extends ConsumerState<DeckSearchView> {
  final DeckSearchService _deckSearchService = DeckSearchService();
  final CardData _cardData = CardData();
  final TextEditingController _searchController = TextEditingController();

  List<String> _availableArchetypes = [];
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
      debugPrint('Fehler beim Laden der Archetypen: $e');
      if (mounted) {
        setState(() => _isLoadingArchetypes = false);
      }
    }
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    ref.read(deckSearchQueryProvider.notifier).state = searchTerm;
    // Archetype zurücksetzen wenn Text-Suche durchgeführt wird
    if (searchTerm.isNotEmpty) {
      ref.read(selectedArchetypeProvider.notifier).state = null;
    }
    // Trigger die Suche
    _triggerSearch();
  }

  void _performArchetypeSearch(String? archetype) {
    ref.read(selectedArchetypeProvider.notifier).state = archetype;
    // Text-Suche zurücksetzen wenn Archetype-Suche durchgeführt wird
    if (archetype != null) {
      ref.read(deckSearchQueryProvider.notifier).state = '';
      _searchController.clear();
    }
    // Trigger die Suche
    _triggerSearch();
  }

  void _triggerSearch() {
    // Verwende den Trigger Provider um die Suche zu aktualisieren
    final currentTrigger = ref.read(deckSearchTriggerProvider);
    ref.read(deckSearchTriggerProvider.notifier).state = currentTrigger + 1;
  }

  void _resetFilters() {
    ref.read(deckSearchQueryProvider.notifier).state = '';
    ref.read(selectedArchetypeProvider.notifier).state = null;
    setState(() {
      _searchController.clear();
    });
  }

  Widget _buildDeckCoverImage(Map<String, dynamic> deck) {
    final coverImageUrl = deck['coverImageUrl'] as String?;

    return SizedBox(
      width: 50,
      height: 50,
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
    final deckSearchResults = ref.watch(deckSearchResultsProvider);
    final selectedArchetype = ref.watch(selectedArchetypeProvider);
    final searchQuery = ref.watch(deckSearchQueryProvider);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Suchbereich
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Deck name...",
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),

                tooltip: 'Search',
              ),

              const SizedBox(width: 4),

              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Reset',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Archetype Dropdown
          if (_isLoadingArchetypes)
            const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableArchetypes.isNotEmpty)
            DropdownMenu<String?>(
              initialSelection: selectedArchetype,
              leadingIcon: const Icon(Icons.category, size: 18),
              label: const Text('Filter by archetype'),
              width: MediaQuery.of(context).size.width - 24,
              menuHeight: 300,
              onSelected: _performArchetypeSearch,
              dropdownMenuEntries: [
                const DropdownMenuEntry<String?>(
                  value: null,
                  label: 'All archetypes',
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

          // Aktive Filter anzeigen
          if (searchQuery.isNotEmpty || selectedArchetype != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  if (searchQuery.isNotEmpty) ...[
                    Chip(
                      label: Text('Name: $searchQuery'),
                      onDeleted: () {
                        ref.read(deckSearchQueryProvider.notifier).state = '';
                        _triggerSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (selectedArchetype != null) ...[
                    Chip(
                      label: Text('Archetype: $selectedArchetype'),
                      onDeleted: () {
                        ref.read(selectedArchetypeProvider.notifier).state =
                            null;
                        _triggerSearch();
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Ergebnisse
          Expanded(
            child: deckSearchResults.when(
              data: (decks) =>
                  _buildResults(decks, searchQuery, selectedArchetype),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $error',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    List<Map<String, dynamic>> decks,
    String searchQuery,
    String? selectedArchetype,
  ) {
    // Zeige leeren State wenn keine Suche aktiv ist
    if (searchQuery.isEmpty && selectedArchetype == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for decks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a deck name or select an archetype',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Zeige leeren State wenn keine Ergebnisse
    if (decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No decks found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'No decks found for "$searchQuery"'
                  : 'No decks found for archetype "$selectedArchetype"',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        final deckName = deck['deckName'] as String? ?? 'Unknown';
        final username = deck['username'] as String? ?? 'Unknown';

        final mainDeck = deck['mainDeck'] as List<dynamic>? ?? [];
        final extraDeck = deck['extraDeck'] as List<dynamic>? ?? [];

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

        final totalCards = mainCount;

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
                Text(
                  '$totalCards cards • by $username',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
  }
}
