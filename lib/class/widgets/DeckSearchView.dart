// DeckSearchView.dart - MIT STANDARD LEERER ANSICHT
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
  final ScrollController _scrollController = ScrollController();

  List<String> _availableArchetypes = [];
  bool _isLoadingArchetypes = true;

  // Cache für gefilterte Decks
  List<Map<String, dynamic>> _filteredDecks = [];
  bool _isSearching = false;
  bool _hasActiveSearch = false; // ✅ NEU: Ob eine aktive Suche läuft

  @override
  void initState() {
    super.initState();
    // Lade erste Seite beim Start (aber zeige sie nicht standardmäßig)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(decksPaginationProvider.notifier).loadFirstPage();
    });

    // Scroll Listener für Pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreDecks();
    }
  }

  void _loadMoreDecks() {
    final paginationState = ref.read(decksPaginationProvider);
    if (!paginationState.isLoading && paginationState.hasMore) {
      ref.read(decksPaginationProvider.notifier).loadNextPage();
    }
  }

  /// Lokale Suche in geladenen Decks
  void _performLocalSearch() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    final selectedArchetype = ref.read(selectedArchetypeProvider);

    // ✅ NEU: Prüfe ob eine aktive Suche vorliegt
    final hasActiveSearch =
        searchTerm.isNotEmpty ||
        (selectedArchetype != null && selectedArchetype != 'All archetypes');

    setState(() {
      _isSearching = true;
      _hasActiveSearch = hasActiveSearch; // ✅ Setze den Status
    });

    // Verwende die bereits geladenen Decks aus der Pagination
    final allDecks = ref.read(refreshableDecksProvider);

    List<Map<String, dynamic>> results = allDecks;

    // Filter nach Suchbegriff
    if (searchTerm.isNotEmpty) {
      results = results.where((deck) {
        final deckName = (deck['deckName'] as String? ?? '').toLowerCase();
        final archetype = (deck['archetype'] as String? ?? '').toLowerCase();
        final description = (deck['description'] as String? ?? '')
            .toLowerCase();

        return deckName.contains(searchTerm) ||
            archetype.contains(searchTerm) ||
            description.contains(searchTerm);
      }).toList();
    }

    // Filter nach Archetyp
    if (selectedArchetype != null && selectedArchetype != 'All archetypes') {
      final archetypeLower = selectedArchetype.toLowerCase();
      results = results.where((deck) {
        final deckArchetype = (deck['archetype'] as String? ?? '')
            .toLowerCase();
        return deckArchetype.contains(archetypeLower);
      }).toList();
    }

    // Sortierung nach Relevanz
    results.sort((a, b) {
      final aName = (a['deckName'] as String? ?? '').toLowerCase();
      final bName = (b['deckName'] as String? ?? '').toLowerCase();

      if (searchTerm.isNotEmpty) {
        if (aName == searchTerm) return -1;
        if (bName == searchTerm) return 1;
        if (aName.startsWith(searchTerm) && !bName.startsWith(searchTerm))
          return -1;
        if (!aName.startsWith(searchTerm) && bName.startsWith(searchTerm))
          return 1;
      }

      return aName.compareTo(bName);
    });

    setState(() {
      _filteredDecks = results;
      _isSearching = false;
    });
  }

  void _performArchetypeSearch(String? archetype) {
    ref.read(selectedArchetypeProvider.notifier).state = archetype;
    if (archetype != null) {
      ref.read(deckSearchQueryProvider.notifier).state = '';
      _searchController.clear();
    }
    _performLocalSearch();
  }

  void _resetFilters() {
    ref.read(deckSearchQueryProvider.notifier).state = '';
    ref.read(selectedArchetypeProvider.notifier).state = null;
    setState(() {
      _searchController.clear();
      _filteredDecks = [];
      _hasActiveSearch = false; // ✅ Zurücksetzen auf keine aktive Suche
    });
  }

  void _refreshDecks() {
    ref.read(decksPaginationProvider.notifier).refresh();
    setState(() {
      _filteredDecks = [];
      _hasActiveSearch = false; // ✅ Zurücksetzen auf keine aktive Suche
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
    final selectedArchetype = ref.watch(selectedArchetypeProvider);
    final searchQuery = ref.watch(cardSearchQueryProvider);

    // Lade Archetypen aus Provider
    final archetypes = ref.watch(preloadedDeckArchetypesProvider);

    // Beobachte Pagination State
    final paginationState = ref.watch(decksPaginationProvider);
    final allDecks = ref.watch(refreshableDecksProvider);

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
                  onSubmitted: (_) => _performLocalSearch(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _performLocalSearch,
                icon: const Icon(Icons.search),
                tooltip: 'Search',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _refreshDecks,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Refresh',
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
          if (archetypes.isNotEmpty)
            DropdownMenu<String?>(
              initialSelection: selectedArchetype,
              leadingIcon: const Icon(Icons.category, size: 18),
              label: const Text('Filter by archetype'),
              width: MediaQuery.of(context).size.width - 24,
              menuHeight: 300,
              onSelected: (value) {
                _performArchetypeSearch(value);
              },
              dropdownMenuEntries: [
                const DropdownMenuEntry<String?>(
                  value: null,
                  label: 'Select archetype',
                ),
                const DropdownMenuEntry<String>(
                  value: 'All archetypes',
                  label: 'All archetypes',
                ),
                ...archetypes.map(
                  (archetype) => DropdownMenuEntry<String>(
                    value: archetype,
                    label: archetype,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Aktive Filter
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
                        _searchController.clear();
                        _performLocalSearch();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (selectedArchetype != null) ...[
                    Chip(
                      label: Text(
                        selectedArchetype == 'All archetypes'
                            ? 'Showing: All archetypes'
                            : 'Archetype: $selectedArchetype',
                      ),
                      onDeleted: () {
                        ref.read(selectedArchetypeProvider.notifier).state =
                            null;
                        _performLocalSearch();
                      },
                    ),
                  ],
                ],
              ),
            ),

          // ✅ NEUE LOGIK: Standardmäßig leere Ansicht anzeigen
          if (!_hasActiveSearch &&
              _searchController.text.isEmpty &&
              selectedArchetype == null)
            _buildEmptyState()
          else if (paginationState.isLoading && paginationState.decks.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading decks...'),
                  ],
                ),
              ),
            )
          else
            // Deck Ergebnisse (nur bei aktiver Suche)
            Expanded(
              child: _buildDeckResults(
                allDecks,
                searchQuery,
                selectedArchetype,
                paginationState,
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ NEUE METHODE: Leere Ansicht wenn keine Suche aktiv
  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Search for Decks',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Enter a deck name in the search field or select an archetype to find decks',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deck Ergebnisse anzeigen
  Widget _buildDeckResults(
    List<dynamic> allDecks,
    String searchQuery,
    String? selectedArchetype,
    DecksPaginationState paginationState,
  ) {
    // Entscheide welche Decks angezeigt werden sollen
    final displayDecks =
        _searchController.text.isNotEmpty || selectedArchetype != null
        ? _filteredDecks
        : []; // ✅ WICHTIG: Keine Decks anzeigen ohne aktive Suche

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (displayDecks.isEmpty) {
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
              'Try adjusting your search or filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    return _buildDeckListView(displayDecks, paginationState);
  }

  Widget _buildDeckListView(
    List<dynamic> decks,
    DecksPaginationState paginationState,
  ) {
    return Column(
      children: [
        // Deck Count Info
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Found ${decks.length} decks',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),

        // Decks List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: decks.length + (paginationState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading Indicator für Pagination
              if (index == decks.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: paginationState.isLoading
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: _loadMoreDecks,
                            child: const Text('Load more decks'),
                          ),
                  ),
                );
              }

              final deck = decks[index];
              final deckName = deck['deckName'] as String? ?? 'Unknown';
              final username = deck['username'] as String? ?? 'Unknown';

              final mainDeck = deck['mainDeck'] as List<dynamic>? ?? [];
              final mainCount = mainDeck.fold<int>(0, (sum, card) {
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
                  subtitle: Text('$mainCount cards • by $username'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    widget.onDeckSelected?.call(deck);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
