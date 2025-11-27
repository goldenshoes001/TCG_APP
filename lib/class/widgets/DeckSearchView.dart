// DeckSearchView.dart - MIT PROVIDER INTEGRATION
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/providers/app_providers.dart';

class DeckSearchView extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onDeckSelected;

  const DeckSearchView({
    super.key,
    this.onDeckSelected,
  }); // ✅ preloadedDecks entfernt

  @override
  ConsumerState<DeckSearchView> createState() => _DeckSearchViewState();
}

class _DeckSearchViewState extends ConsumerState<DeckSearchView> {
  final DeckSearchService _deckSearchService = DeckSearchService();
  final CardData _cardData = CardData();
  final TextEditingController _searchController = TextEditingController();

  List<String> _availableArchetypes = [];
  bool _isLoadingArchetypes = true;

  // ✅ Cache für gefilterte Decks
  List<Map<String, dynamic>> _filteredDecks = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Archetypen werden jetzt aus dem Provider geladen
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ OPTIMIERT: Lokale Suche in Provider-Decks
  void _performLocalSearch() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    final selectedArchetype = ref.read(selectedArchetypeProvider);

    // ✅ Lade Decks aus Provider
    final decksAsync = ref.read(refreshableDecksProvider);

    decksAsync.when(
      data: (allDecks) {
        setState(() {
          _isSearching = true;
        });

        List<Map<String, dynamic>> results = allDecks;

        // Filter nach Suchbegriff
        if (searchTerm.isNotEmpty) {
          results = results.where((deck) {
            final deckName = (deck['deckName'] as String? ?? '').toLowerCase();
            final archetype = (deck['archetype'] as String? ?? '')
                .toLowerCase();
            final description = (deck['description'] as String? ?? '')
                .toLowerCase();

            return deckName.contains(searchTerm) ||
                archetype.contains(searchTerm) ||
                description.contains(searchTerm);
          }).toList();
        }

        // Filter nach Archetyp
        if (selectedArchetype != null &&
            selectedArchetype != 'All archetypes') {
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
      },
      loading: () {
        setState(() {
          _isSearching = true;
        });
      },
      error: (error, stack) {
        print('❌ Error loading decks: $error');
        setState(() {
          _filteredDecks = [];
          _isSearching = false;
        });
      },
    );
  }

  void _performArchetypeSearch(String? archetype) {
    ref.read(selectedArchetypeProvider.notifier).state = archetype;
    if (archetype != null) {
      ref.read(deckSearchQueryProvider.notifier).state = '';
      _searchController.clear();
    }
    _performLocalSearch(); // ✅ Sofort lokale Suche durchführen
  }

  void _resetFilters() {
    ref.read(deckSearchQueryProvider.notifier).state = '';
    ref.read(selectedArchetypeProvider.notifier).state = null;
    setState(() {
      _searchController.clear();
      _filteredDecks = [];
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

    // ✅ Lade Archetypen aus Provider
    final archetypes = ref.watch(preloadedDeckArchetypesProvider);

    // ✅ Beobachte Decks aus Provider
    final decksAsync = ref.watch(refreshableDecksProvider);

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

          // ✅ Ergebnisse aus Provider
          Expanded(
            child: decksAsync.when(
              data: (allDecks) {
                // Wenn Filter aktiv sind, zeige gefilterte Liste
                final displayDecks =
                    _searchController.text.isNotEmpty ||
                        selectedArchetype != null
                    ? _filteredDecks
                    : [];

                return _buildDeckResults(
                  displayDecks,
                  searchQuery,
                  selectedArchetype,
                );
              },
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
                    const SizedBox(height: 16),
                    Text('Error loading decks: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Deck Ergebnisse anzeigen
  Widget _buildDeckResults(
    List<dynamic> decks,
    String searchQuery,
    String? selectedArchetype,
  ) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

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
    );
  }
}
