import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/DeckSearchView.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/search_results_view.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  @override
  ConsumerState<Search> createState() => _MetaState();
}

class _MetaState extends ConsumerState<Search>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _suchfeld = TextEditingController();
  final TextEditingController _atkController = TextEditingController();
  final TextEditingController _defController = TextEditingController();

  bool _showFilters = true;
  int _dropdownResetKey = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _suchfeld.dispose();
    _atkController.dispose();
    _defController.dispose();
    super.dispose();
  }

  void _performTextSearch(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      ref.read(cardSearchQueryProvider.notifier).state = '';
      // Wenn Suchwort leer ist, aber Filter aktiv sind, zeige trotzdem Ergebnisse
      final filterState = ref.read(filterProvider);
      final hasFilters =
          filterState.selectedType != null ||
          filterState.selectedRace != null ||
          filterState.selectedAttribute != null ||
          filterState.selectedArchetype != null ||
          filterState.selectedLevel != null ||
          _atkController.text.trim().isNotEmpty ||
          _defController.text.trim().isNotEmpty ||
          filterState.selectedScale != null ||
          filterState.selectedLinkRating != null ||
          filterState.selectedBanlistTCG != null ||
          filterState.selectedBanlistOCG != null;

      if (!hasFilters) {
        setState(() {
          _showFilters = true;
        });
      }
      return;
    }
    /*

  - getcarddata
  - app_provider
  - search.dart

 */
    ref.read(cardSearchQueryProvider.notifier).state = trimmedValue;
    ref.read(selectedCardProvider.notifier).state = null;
    setState(() {
      _showFilters = false;
    });
  }

  void _performCardSearch() {
    final filterState = ref.watch(filterProvider);
    final hasQuery = _suchfeld.text.trim().isNotEmpty;

    // Prüfe ob mindestens ein Filter ODER ein Suchwort gesetzt ist
    final hasFilters =
        filterState.selectedType != null ||
        filterState.selectedRace != null ||
        filterState.selectedAttribute != null ||
        filterState.selectedArchetype != null ||
        filterState.selectedLevel != null ||
        _atkController.text.trim().isNotEmpty ||
        _defController.text.trim().isNotEmpty ||
        filterState.selectedScale != null ||
        filterState.selectedLinkRating != null ||
        filterState.selectedBanlistTCG != null ||
        filterState.selectedBanlistOCG != null;

    if (!hasQuery && !hasFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Suchwort oder Filter eingeben.')),
      );
      return;
    }

    // WICHTIG: Update ALLE Werte im State
    ref.read(cardSearchQueryProvider.notifier).state = _suchfeld.text.trim();

    // ATK/DEF Werte aktualisieren
    ref
        .read(filterProvider.notifier)
        .updateAtkValue(_atkController.text.trim());
    ref
        .read(filterProvider.notifier)
        .updateDefValue(_defController.text.trim());

    // UI aktualisieren
    setState(() {
      _showFilters = false;
    });

    // Debug-Ausgabe
    print('🔍 Suche durchgeführt:');
    print('   Query: "${_suchfeld.text.trim()}"');
    print('   Filter aktiv: $hasFilters');
  }

  void _resetFilters() {
    ref.read(filterProvider.notifier).reset();
    ref.read(cardSearchQueryProvider.notifier).state = '';
    ref.read(deckSearchQueryProvider.notifier).state = '';
    ref.read(selectedCardProvider.notifier).state = null;
    ref.read(selectedDeckProvider.notifier).state = null;

    setState(() {
      _suchfeld.clear();
      _atkController.clear();
      _defController.clear();
      _showFilters = true;
      _dropdownResetKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final selectedCard = ref.watch(selectedCardProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);
    final cardSearchQuery = ref.watch(cardSearchQueryProvider);
    final filterState = ref.watch(filterProvider);

    // Loading States für Filter-Daten
    final typesAsync = ref.watch(typesProvider);
    final racesAsync = ref.watch(racesProvider);
    final attributesAsync = ref.watch(attributesProvider);
    final archetypesAsync = ref.watch(archetypesProvider);

    if (selectedCard != null) {
      return CardDetailView(
        cardData: selectedCard,
        onBack: () {
          ref.read(selectedCardProvider.notifier).state = null;
        },
      );
    }

    if (selectedDeck != null) {
      return DeckViewer(
        deckData: selectedDeck,
        onBack: () {
          ref.read(selectedDeckProvider.notifier).state = null;
        },
      );
    }

    // Prüfe ob Filter-Daten geladen werden
    final isLoadingFilters =
        typesAsync.isLoading ||
        racesAsync.isLoading ||
        attributesAsync.isLoading ||
        archetypesAsync.isLoading;

    if (isLoadingFilters && _tabController.index == 0) {
      return const Center(child: Text('Filter get loaded...'));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cards'),
            Tab(text: 'Decks'),
          ],
          onTap: (index) {
            ref.read(cardSearchQueryProvider.notifier).state = '';
            ref.read(deckSearchQueryProvider.notifier).state = '';
            ref.read(selectedArchetypeProvider.notifier).state = null;
            ref
                .read(deckSearchTriggerProvider.notifier)
                .state++; // 🔄 Trigger reset
            ref.read(selectedCardProvider.notifier).state = null;
            ref.read(selectedDeckProvider.notifier).state = null;
            setState(() {
              _showFilters = index == 0;
              _suchfeld.clear();
            });
          },
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 350),

                if (_tabController.index == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: "search Card...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        onSubmitted: _performTextSearch,
                        controller: _suchfeld,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),

                if (_tabController.index == 0 &&
                    !_showFilters &&
                    (cardSearchQuery.isNotEmpty ||
                        filterState.selectedType != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFilters = true;
                            });
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Show Filter'),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _showFilters
                          ? _buildFilterView(
                              typesAsync,
                              racesAsync,
                              attributesAsync,
                              archetypesAsync,
                            )
                          : _buildSearchResults(),
                      DeckSearchView(
                        onDeckSelected: (deck) {
                          ref.read(selectedDeckProvider.notifier).state = deck;
                        },
                      ),
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

  Widget _buildSearchResults() {
    final cardSearchQuery = ref.watch(cardSearchQueryProvider);
    final filterState = ref.watch(filterProvider);

    // Prüfe ob überhaupt eine Suche aktiv ist
    final hasQuery = cardSearchQuery.isNotEmpty;
    final hasFilters =
        filterState.selectedType != null ||
        filterState.selectedRace != null ||
        filterState.selectedAttribute != null ||
        filterState.selectedArchetype != null ||
        filterState.selectedLevel != null ||
        filterState.atkValue.isNotEmpty ||
        filterState.defValue.isNotEmpty ||
        filterState.selectedScale != null ||
        filterState.selectedLinkRating != null ||
        filterState.selectedBanlistTCG != null ||
        filterState.selectedBanlistOCG != null;

    // Verwende immer den kombinierten Search Provider
    final combinedResultsAsync = ref.watch(combinedSearchResultsProvider);

    return combinedResultsAsync.when(
      data: (results) => SearchResultsView(
        searchFuture: Future.value(results),
        onCardSelected: (card) {
          ref.read(selectedCardProvider.notifier).state = card;
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildFilterView(
    AsyncValue<List<String>> typesAsync,
    AsyncValue<List<String>> racesAsync,
    AsyncValue<List<String>> attributesAsync,
    AsyncValue<List<String>> archetypesAsync,
  ) {
    return typesAsync.when(
      data: (types) => racesAsync.when(
        data: (races) => attributesAsync.when(
          data: (attributes) => archetypesAsync.when(
            data: (archetypes) =>
                _buildFilterForm(types, races, attributes, archetypes),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading archetypes')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading attributes')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading races')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading types')),
    );
  }

  Widget _buildFilterForm(
    List<String> types,
    List<String> races,
    List<String> attributes,
    List<String> archetypes,
  ) {
    final filterState = ref.watch(filterProvider);
    const double spacing = 12.0;
    final List<String> banlistStatuses = [
      'Forbidden',
      'Limited',
      'Semi-Limited',
    ];
    final List<String> operators = ['min', '=', 'max'];

    return SingleChildScrollView(
      child: Column(
        key: ValueKey(_dropdownResetKey),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Dropdown
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: DropdownMenu<String>(
              label: const Text('Type'),
              initialSelection: filterState.selectedType,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: types.map((item) {
                return DropdownMenuEntry<String>(value: item, label: item);
              }).toList(),
              onSelected: (value) {
                ref.read(filterProvider.notifier).updateType(value);
              },
            ),
          ),
          const SizedBox(height: spacing),

          // Race & Attribute Row
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  label: const Text('Race'),
                  initialSelection: filterState.selectedRace,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: races.map((item) {
                    return DropdownMenuEntry<String>(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    ref.read(filterProvider.notifier).updateRace(value);
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: const Text('Attribut'),
                  initialSelection: filterState.selectedAttribute,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: attributes.map((item) {
                    return DropdownMenuEntry<String>(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    ref.read(filterProvider.notifier).updateAttribute(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: spacing),

          // Archetype
          DropdownMenu<String>(
            label: const Text('Archetyp'),
            initialSelection: filterState.selectedArchetype,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: archetypes.map((item) {
              return DropdownMenuEntry<String>(value: item, label: item);
            }).toList(),
            onSelected: (value) {
              ref.read(filterProvider.notifier).updateArchetype(value);
            },
          ),
          const SizedBox(height: spacing),

          // Level with Operator
          _buildDropdownWithOperator(
            label: 'Level',
            value: filterState.selectedLevel,
            items: List.generate(14, (index) => index.toString()),
            operator: filterState.levelOperator,
            operators: operators,
            onChanged: (value) {
              ref.read(filterProvider.notifier).updateLevel(value);
            },
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateLevelOperator(value!);
            },
          ),
          const SizedBox(height: spacing),

          // Scale with Operator
          _buildDropdownWithOperator(
            label: 'Scale',
            value: filterState.selectedScale,
            items: List.generate(14, (index) => index.toString()),
            operator: filterState.scaleOperator,
            operators: operators,
            onChanged: (value) {
              ref.read(filterProvider.notifier).updateScale(value);
            },
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateScaleOperator(value!);
            },
          ),
          const SizedBox(height: spacing),

          // Link Rating with Operator
          _buildDropdownWithOperator(
            label: 'Link Rating',
            value: filterState.selectedLinkRating,
            items: List.generate(6, (index) => (index + 1).toString()),
            operator: filterState.linkRatingOperator,
            operators: operators,
            onChanged: (value) {
              ref.read(filterProvider.notifier).updateLinkRating(value);
            },
            onOperatorChanged: (value) {
              ref
                  .read(filterProvider.notifier)
                  .updateLinkRatingOperator(value!);
            },
          ),
          const SizedBox(height: spacing),

          // ATK with Operator
          _buildNumericInputWithOperator(
            label: 'ATK',
            controller: _atkController,
            operator: filterState.atkOperator,
            operators: operators,
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateAtkOperator(value!);
            },
          ),
          const SizedBox(height: spacing),

          // DEF with Operator
          _buildNumericInputWithOperator(
            label: 'DEF',
            controller: _defController,
            operator: filterState.defOperator,
            operators: operators,
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateDefOperator(value!);
            },
          ),
          const SizedBox(height: spacing),

          // Bannlist Row
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  label: const Text('TCG Bannliste'),
                  initialSelection: filterState.selectedBanlistTCG,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: banlistStatuses.map((item) {
                    return DropdownMenuEntry<String>(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    ref.read(filterProvider.notifier).updateBanlistTCG(value);
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: const Text('OCG Bannliste'),
                  initialSelection: filterState.selectedBanlistOCG,
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: banlistStatuses.map((item) {
                    return DropdownMenuEntry<String>(value: item, label: item);
                  }).toList(),
                  onSelected: (value) {
                    ref.read(filterProvider.notifier).updateBanlistOCG(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: spacing),

          // Search & Reset Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _performCardSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('search'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownWithOperator({
    required String label,
    required String? value,
    required List<String> items,
    required String operator,
    required List<String> operators,
    required void Function(String?) onChanged,
    required void Function(String?) onOperatorChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownMenu<String>(
            initialSelection: operator,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: operators.map((op) {
              return DropdownMenuEntry<String>(value: op, label: op);
            }).toList(),
            onSelected: onOperatorChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownMenu<String>(
            label: Text(label),
            initialSelection: value,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: items.map((item) {
              return DropdownMenuEntry<String>(value: item, label: item);
            }).toList(),
            onSelected: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNumericInputWithOperator({
    required String label,
    required TextEditingController controller,
    required String operator,
    required List<String> operators,
    required void Function(String?) onOperatorChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownMenu<String>(
            initialSelection: operator,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: operators.map((op) {
              return DropdownMenuEntry<String>(value: op, label: op);
            }).toList(),
            onSelected: onOperatorChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
