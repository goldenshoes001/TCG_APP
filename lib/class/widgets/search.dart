import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/DeckSearchView.dart';
import 'package:tcg_app/class/widgets/helperClass allgemein/search_results_view.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';
import 'package:tcg_app/providers/app_providers.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key}); // ✅ PARAMETER ENTFERNT

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

    _atkController.addListener(_onTextFieldChanged);
    _defController.addListener(_onTextFieldChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _suchfeld.dispose();
    _atkController.removeListener(_onTextFieldChanged);
    _defController.removeListener(_onTextFieldChanged);
    _atkController.dispose();
    _defController.dispose();
    super.dispose();
  }

  void _onTextFieldChanged() {
    setState(() {});
  }

  void _performTextSearch(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      ref.read(cardSearchQueryProvider.notifier).state = '';
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

    ref.read(cardSearchQueryProvider.notifier).state = trimmedValue;
    ref.read(selectedCardProvider.notifier).state = null;
    setState(() {
      _showFilters = false;
    });
  }

  void _performCardSearch() {
    final filterState = ref.watch(filterProvider);
    final hasQuery = _suchfeld.text.trim().isNotEmpty;

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
        const SnackBar(content: Text('Pls search word or use filter.')),
      );
      return;
    }

    ref.read(cardSearchQueryProvider.notifier).state = _suchfeld.text.trim();
    ref
        .read(filterProvider.notifier)
        .updateAtkValue(_atkController.text.trim());
    ref
        .read(filterProvider.notifier)
        .updateDefValue(_defController.text.trim());

    setState(() {
      _showFilters = false;
    });
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

    final types = ref.watch(combinedTypesProvider);
    final races = ref.watch(combinedRacesProvider);
    final attributes = ref.watch(combinedAttributesProvider);
    final archetypes = ref.watch(combinedArchetypesProvider);

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
            ref.read(deckSearchTriggerProvider.notifier).state++;
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
                      _showFilters ? _buildFilterView() : _buildSearchResults(),
                      // ✅ KEINE preloadedDecks Parameter mehr - verwendet Provider
                      DeckSearchView(
                        onDeckSelected: (deck) {
                          ref.read(selectedDeckProvider.notifier).state = deck;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {});
                          });
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

  Widget _buildFilterView() {
    final types = ref.watch(combinedTypesProvider);
    final races = ref.watch(combinedRacesProvider);
    final attributes = ref.watch(combinedAttributesProvider);
    final archetypes = ref.watch(combinedArchetypesProvider);

    return _buildFilterForm(types, races, attributes, archetypes);
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
    const activeColor = Colors.lightBlue;

    return SingleChildScrollView(
      child: Column(
        key: ValueKey(_dropdownResetKey),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Dropdown
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: DropdownMenu<String>(
              label: null,
              textStyle: TextStyle(
                color: filterState.selectedType != null ? activeColor : null,
              ),
              initialSelection: filterState.selectedType ?? 'Type',
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: [
                const DropdownMenuEntry<String>(value: 'Type', label: 'Type'),
                ...types.map((item) {
                  return DropdownMenuEntry<String>(value: item, label: item);
                }),
              ],
              onSelected: (value) {
                if (value == 'Type') {
                  ref.read(filterProvider.notifier).updateType(null);
                } else {
                  ref.read(filterProvider.notifier).updateType(value);
                }
              },
            ),
          ),
          const SizedBox(height: spacing),

          // Race & Attribute Row
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: filterState.selectedRace != null
                        ? activeColor
                        : null,
                  ),
                  initialSelection: filterState.selectedRace ?? 'Race',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'Race',
                      label: 'Race',
                    ),
                    ...races.map((item) {
                      return DropdownMenuEntry<String>(
                        value: item,
                        label: item,
                      );
                    }),
                  ],
                  onSelected: (value) {
                    if (value == 'Race') {
                      ref.read(filterProvider.notifier).updateRace(null);
                    } else {
                      ref.read(filterProvider.notifier).updateRace(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: filterState.selectedAttribute != null
                        ? activeColor
                        : null,
                  ),
                  initialSelection: filterState.selectedAttribute ?? 'Attribut',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'Attribut',
                      label: 'Attribut',
                    ),
                    ...attributes.map((item) {
                      return DropdownMenuEntry<String>(
                        value: item,
                        label: item,
                      );
                    }),
                  ],
                  onSelected: (value) {
                    if (value == 'Attribut') {
                      ref.read(filterProvider.notifier).updateAttribute(null);
                    } else {
                      ref.read(filterProvider.notifier).updateAttribute(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: spacing),

          // Archetype
          DropdownMenu<String>(
            label: null,
            textStyle: TextStyle(
              color: filterState.selectedArchetype != null ? activeColor : null,
            ),
            initialSelection: filterState.selectedArchetype ?? 'All archetypes',
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String>(
                value: 'All archetypes',
                label: 'All archetypes',
              ),
              ...archetypes.map((item) {
                return DropdownMenuEntry<String>(value: item, label: item);
              }),
            ],
            onSelected: (value) {
              if (value == 'All archetypes') {
                ref.read(filterProvider.notifier).updateArchetype(null);
              } else {
                ref.read(filterProvider.notifier).updateArchetype(value);
              }
            },
          ),
          const SizedBox(height: spacing),

          // Level with Operator
          _buildOperatorDropdown(
            label: 'Level',
            value: filterState.selectedLevel,
            items: List.generate(14, (index) => index.toString()),
            operator: filterState.levelOperator,
            onChanged: (value) {
              if (value == 'Level') {
                ref.read(filterProvider.notifier).updateLevel(null);
              } else {
                ref.read(filterProvider.notifier).updateLevel(value);
              }
            },
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateLevelOperator(value!);
            },
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // Scale with Operator
          _buildOperatorDropdown(
            label: 'Scale',
            value: filterState.selectedScale,
            items: List.generate(14, (index) => index.toString()),
            operator: filterState.scaleOperator,
            onChanged: (value) {
              if (value == 'Scale') {
                ref.read(filterProvider.notifier).updateScale(null);
              } else {
                ref.read(filterProvider.notifier).updateScale(value);
              }
            },
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateScaleOperator(value!);
            },
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // Link Rating with Operator
          _buildOperatorDropdown(
            label: 'Link Rating',
            value: filterState.selectedLinkRating,
            items: List.generate(6, (index) => (index + 1).toString()),
            operator: filterState.linkRatingOperator,
            onChanged: (value) {
              if (value == 'Link Rating') {
                ref.read(filterProvider.notifier).updateLinkRating(null);
              } else {
                ref.read(filterProvider.notifier).updateLinkRating(value);
              }
            },
            onOperatorChanged: (value) {
              ref
                  .read(filterProvider.notifier)
                  .updateLinkRatingOperator(value!);
            },
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // ATK with Operator
          _buildOperatorTextInput(
            label: 'ATK',
            controller: _atkController,
            operator: filterState.atkOperator,
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateAtkOperator(value!);
            },
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // DEF with Operator
          _buildOperatorTextInput(
            label: 'DEF',
            controller: _defController,
            operator: filterState.defOperator,
            onOperatorChanged: (value) {
              ref.read(filterProvider.notifier).updateDefOperator(value!);
            },
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // Bannlist Row
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: filterState.selectedBanlistTCG != null
                        ? activeColor
                        : null,
                  ),
                  initialSelection:
                      filterState.selectedBanlistTCG ?? 'TCG Bannliste',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'TCG Bannliste',
                      label: 'TCG Bannliste',
                    ),
                    ...banlistStatuses.map((item) {
                      return DropdownMenuEntry<String>(
                        value: item,
                        label: item,
                      );
                    }),
                  ],
                  onSelected: (value) {
                    if (value == 'TCG Bannliste') {
                      ref.read(filterProvider.notifier).updateBanlistTCG(null);
                    } else {
                      ref.read(filterProvider.notifier).updateBanlistTCG(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: filterState.selectedBanlistOCG != null
                        ? activeColor
                        : null,
                  ),
                  initialSelection:
                      filterState.selectedBanlistOCG ?? 'OCG Bannliste',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'OCG Bannliste',
                      label: 'OCG Bannliste',
                    ),
                    ...banlistStatuses.map((item) {
                      return DropdownMenuEntry<String>(
                        value: item,
                        label: item,
                      );
                    }),
                  ],
                  onSelected: (value) {
                    if (value == 'OCG Bannliste') {
                      ref.read(filterProvider.notifier).updateBanlistOCG(null);
                    } else {
                      ref.read(filterProvider.notifier).updateBanlistOCG(value);
                    }
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

  Widget _buildOperatorDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String operator,
    required void Function(String?) onChanged,
    required void Function(String?) onOperatorChanged,
    required Color activeColor,
  }) {
    final List<String> operators = ['min', '=', 'max'];

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
            label: null,
            textStyle: TextStyle(color: value != null ? activeColor : null),
            initialSelection: value ?? label,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              DropdownMenuEntry<String>(value: label, label: label),
              ...items.map((item) {
                return DropdownMenuEntry<String>(value: item, label: item);
              }),
            ],
            onSelected: (selectedValue) {
              if (selectedValue == label) {
                onChanged(null);
              } else {
                onChanged(selectedValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOperatorTextInput({
    required String label,
    required TextEditingController controller,
    required String operator,
    required void Function(String?) onOperatorChanged,
    required Color activeColor,
  }) {
    final List<String> operators = ['min', '=', 'max'];

    return Row(
      children: [
        SizedBox(
          width: 80,
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
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: controller.text.isNotEmpty ? activeColor : null,
            ),
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
