// meta.dart - MIT DECK-SUCHE
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/helperClass%20allgemein/search_results_view.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';

class Meta extends StatefulWidget {
  final List<String>? preloadedTypes;
  final List<String>? preloadedRaces;
  final List<String>? preloadedAttributes;
  final List<String>? preloadedArchetypes;

  const Meta({
    super.key,
    this.preloadedTypes,
    this.preloadedRaces,
    this.preloadedAttributes,
    this.preloadedArchetypes,
  });

  @override
  State<Meta> createState() => _MetaState();
}

class _MetaState extends State<Meta>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final CardData _cardData = CardData();
  final DeckSearchService _deckSearchService = DeckSearchService();

  late TabController _tabController;

  Future<List<Map<String, dynamic>>>? _cardSearchFuture;
  Future<List<Map<String, dynamic>>>? _deckSearchFuture;
  Map<String, dynamic>? _selectedCard;
  Map<String, dynamic>? _selectedDeck;
  bool _showFilters = true;

  final TextEditingController _suchfeld = TextEditingController();

  // Filter-Werte für Karten
  String? _selectedType;
  String? _selectedRace;
  String? _selectedAttribute;
  String? _selectedArchetype;
  String? _selectedBanlistTCG;
  String? _selectedBanlistOCG;
  String? _selectedLevel;
  String? _selectedScale;
  String? _selectedLinkRating;

  List<String> _types = [];
  List<String> _races = [];
  List<String> _attributes = [];
  List<String> _archetypes = [];

  bool _filtersLoading = true;

  final TextEditingController _atkController = TextEditingController();
  final TextEditingController _defController = TextEditingController();

  String _atkOperator = '=';
  String _defOperator = '=';
  String _scaleOperator = '=';
  String _linkRatingOperator = '=';
  String _levelOperator = '=';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    if (widget.preloadedTypes != null &&
        widget.preloadedRaces != null &&
        widget.preloadedAttributes != null &&
        widget.preloadedArchetypes != null) {
      if (mounted) {
        setState(() {
          _types = widget.preloadedTypes!;
          _races = widget.preloadedRaces!;
          _attributes = widget.preloadedAttributes!;
          _archetypes = widget.preloadedArchetypes!;
          _filtersLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _filtersLoading = true);
    }

    try {
      final loadedTypes = await _cardData.getFacetValues('type');
      final loadedRaces = await _cardData.getFacetValues('race');
      final loadedAttributes = await _cardData.getFacetValues('attribute');
      final loadedArchetypes = await _cardData.getFacetValues('archetype');

      if (mounted) {
        setState(() {
          _types = loadedTypes;
          _races = loadedRaces;
          _attributes = loadedAttributes;
          _archetypes = loadedArchetypes;
          _filtersLoading = false;
        });
      }
    } catch (e) {
      print('Fehler beim Laden der Filterdaten: $e');
      if (mounted) {
        setState(() => _filtersLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _suchfeld.dispose();
    _atkController.dispose();
    _defController.dispose();
    super.dispose();
  }

  final List<String> _banlistStatuses = [
    'Forbidden',
    'Limited',
    'Semi-Limited',
  ];

  final List<String> _operators = ['min', '=', 'max'];

  void _resetFiltersState() {
    setState(() {
      _selectedType = null;
      _selectedRace = null;
      _selectedAttribute = null;
      _selectedArchetype = null;
      _selectedBanlistTCG = null;
      _selectedBanlistOCG = null;
      _selectedLevel = null;
      _selectedScale = null;
      _selectedLinkRating = null;
      _suchfeld.clear();
      _atkController.clear();
      _defController.clear();
      _atkOperator = '=';
      _defOperator = '=';
      _scaleOperator = '=';
      _linkRatingOperator = '=';
      _levelOperator = '=';
    });
  }

  void _performCardSearch() {
    if (_selectedType == null &&
        _selectedRace == null &&
        _selectedAttribute == null &&
        _selectedArchetype == null &&
        _selectedLevel == null &&
        _atkController.text.trim().isEmpty &&
        _defController.text.trim().isEmpty &&
        _selectedScale == null &&
        _selectedLinkRating == null &&
        _selectedBanlistTCG == null &&
        _selectedBanlistOCG == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie mindestens einen Filter aus.'),
        ),
      );
      return;
    }

    _suchfeld.clear();

    String? atkFilter;
    String? defFilter;
    int? scaleValue;
    String? scaleOperatorValue;
    int? linkRatingValue;
    String? linkRatingOperatorValue;
    int? levelValue;
    String? levelOperatorValue;

    if (_atkController.text.trim().isNotEmpty) {
      final atkOp = _atkOperator == 'min'
          ? '>='
          : _atkOperator == 'max'
          ? '<='
          : '=';
      atkFilter = '$atkOp${_atkController.text.trim()}';
    }
    if (_defController.text.trim().isNotEmpty) {
      final defOp = _defOperator == 'min'
          ? '>='
          : _defOperator == 'max'
          ? '<='
          : '=';
      defFilter = '$defOp${_defController.text.trim()}';
    }
    if (_selectedScale != null) {
      scaleValue = int.tryParse(_selectedScale!);
      scaleOperatorValue = _scaleOperator;
    }
    if (_selectedLinkRating != null) {
      linkRatingValue = int.tryParse(_selectedLinkRating!);
      linkRatingOperatorValue = _linkRatingOperator;
    }
    if (_selectedLevel != null) {
      levelValue = int.tryParse(_selectedLevel!);
      levelOperatorValue = _levelOperator;
    }

    setState(() {
      _cardSearchFuture = _cardData
          .searchWithFilters(
            type: _selectedType,
            race: _selectedRace,
            attribute: _selectedAttribute,
            archetype: _selectedArchetype,
            level: levelValue,
            levelOperator: levelOperatorValue,
            linkRating: linkRatingValue,
            linkRatingOperator: linkRatingOperatorValue,
            scale: scaleValue,
            scaleOperator: scaleOperatorValue,
            atk: atkFilter,
            def: defFilter,
            banlistTCG: _selectedBanlistTCG,
            banlistOCG: _selectedBanlistOCG,
          )
          .then((list) async {
            final cards = list.cast<Map<String, dynamic>>();
            await _cardData.preloadCardImages(cards);
            return cards;
          });
      _selectedCard = null;
      _showFilters = false;
    });
  }

  void _performTextSearch(String value) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      setState(() {
        _cardSearchFuture = Future.value([]);
        _deckSearchFuture = Future.value([]);
      });
      return;
    }

    if (_tabController.index == 0) {
      // Karten-Textsuche
      setState(() {
        _cardSearchFuture = _cardData.ergebniseAnzeigen(trimmedValue).then((
          list,
        ) async {
          final cards = list.cast<Map<String, dynamic>>();
          await _cardData.preloadCardImages(cards);
          return cards;
        });
        _selectedCard = null;
        _showFilters = false;
      });
    } else {
      // Deck-Suche
      setState(() {
        _deckSearchFuture = _deckSearchService.searchDecks(trimmedValue);
        _selectedDeck = null;
      });
    }
  }

  void _resetFilters() {
    _resetFiltersState();
    setState(() {
      _cardSearchFuture = null;
      _deckSearchFuture = null;
      _selectedCard = null;
      _selectedDeck = null;
      _showFilters = true;
    });
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

            final mainDeck = deck['mainDeck'] as List<dynamic>? ?? [];
            final cardCount = mainDeck.fold(0, (sum, card) {
              if (card is Map<String, dynamic>) {
                return sum + (card['count'] as int? ?? 0);
              }
              return sum;
            });

            return Card(
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

  Widget _buildDeckDetail() {
    if (_selectedDeck == null) return const SizedBox.shrink();

    final deckName = _selectedDeck!['deckName'] as String? ?? 'Unbekannt';
    final archetype = _selectedDeck!['archetype'] as String? ?? '';
    final description = _selectedDeck!['description'] as String? ?? '';
    final username = _selectedDeck!['username'] as String? ?? 'Unbekannt';

    final mainDeck = _selectedDeck!['mainDeck'] as List<dynamic>? ?? [];
    final extraDeck = _selectedDeck!['extraDeck'] as List<dynamic>? ?? [];
    final sideDeck = _selectedDeck!['sideDeck'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedDeck = null;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    deckName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (archetype.isNotEmpty) ...[
              Text('Archetypen: $archetype'),
              const SizedBox(height: 4),
            ],

            Text('Von: $username'),
            const SizedBox(height: 8),

            if (description.isNotEmpty) ...[
              Text(
                'Beschreibung:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(description),
              const SizedBox(height: 16),
            ],

            Text(
              'Main Deck (${mainDeck.fold(0, (sum, card) => sum + ((card as Map)['count'] as int? ?? 0))} Karten)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...mainDeck.map((cardData) {
              final card = cardData as Map<String, dynamic>;
              return ListTile(
                dense: true,
                title: Text('${card['count']}x ${card['name']}'),
                onTap: () {
                  setState(() {
                    _selectedCard = card;
                    _selectedDeck = null;
                  });
                },
              );
            }),

            const SizedBox(height: 16),

            if (extraDeck.isNotEmpty) ...[
              Text(
                'Extra Deck (${extraDeck.fold(0, (sum, card) => sum + ((card as Map)['count'] as int? ?? 0))} Karten)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...extraDeck.map((cardData) {
                final card = cardData as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  title: Text('${card['count']}x ${card['name']}'),
                  onTap: () {
                    setState(() {
                      _selectedCard = card;
                      _selectedDeck = null;
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
            ],

            if (sideDeck.isNotEmpty) ...[
              Text(
                'Side Deck (${sideDeck.fold(0, (sum, card) => sum + ((card as Map)['count'] as int? ?? 0))} Karten)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...sideDeck.map((cardData) {
                final card = cardData as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  title: Text('${card['count']}x ${card['name']}'),
                  onTap: () {
                    setState(() {
                      _selectedCard = card;
                      _selectedDeck = null;
                    });
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_selectedCard != null) {
      return _buildCardDetail();
    }

    if (_selectedDeck != null) {
      return _buildDeckDetail();
    }

    if (_filtersLoading && _tabController.index == 0) {
      return Center(
        child: Text(
          'Filter werden geladen...',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
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
              _selectedCard = null;
              _selectedDeck = null;
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

                TextField(
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? "Karte suchen..."
                        : "Deck suchen...",
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: _performTextSearch,
                  controller: _suchfeld,
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 55),

                if (_tabController.index == 0 &&
                    !_showFilters &&
                    _cardSearchFuture != null)
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
                          label: const Text('Filter anzeigen'),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Karten-Tab
                      _showFilters
                          ? SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterGrid(),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 40,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _performCardSearch,
                                          icon: const Icon(Icons.search),
                                          label: const Text('Suchen'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _resetFilters,
                                          icon: const Icon(Icons.clear),
                                          label: const Text('Zurücksetzen'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : SearchResultsView(
                              searchFuture: _cardSearchFuture,
                              cardData: _cardData,
                              onCardSelected: (card) {
                                setState(() {
                                  _selectedCard = card;
                                });
                              },
                            ),

                      // Decks-Tab
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

  Widget _buildFilterGrid() {
    const double spacing = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Type',
          value: _selectedType,
          items: _types,
          onChanged: (value) => setState(() => _selectedType = value),
        ),
        const SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Race',
                value: _selectedRace,
                items: _races,
                onChanged: (value) => setState(() => _selectedRace = value),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _buildDropdown(
                label: 'Attribut',
                value: _selectedAttribute,
                items: _attributes,
                onChanged: (value) =>
                    setState(() => _selectedAttribute = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: spacing),

        _buildDropdown(
          label: 'Archetyp',
          value: _selectedArchetype,
          items: _archetypes,
          onChanged: (value) => setState(() => _selectedArchetype = value),
        ),
        const SizedBox(height: spacing),

        _buildDropdownWithOperator(
          label: 'Level',
          value: _selectedLevel,
          items: List.generate(14, (index) => index.toString()),
          operator: _levelOperator,
          onChanged: (value) {
            setState(() {
              _selectedLevel = value;
            });
          },
          onOperatorChanged: (value) {
            setState(() => _levelOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildDropdownWithOperator(
          label: 'Scale',
          value: _selectedScale,
          items: List.generate(14, (index) => index.toString()),
          operator: _scaleOperator,
          onChanged: (value) {
            setState(() {
              _selectedScale = value;
            });
          },
          onOperatorChanged: (value) {
            setState(() => _scaleOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildDropdownWithOperator(
          label: 'Link Rating',
          value: _selectedLinkRating,
          items: List.generate(6, (index) => (index + 1).toString()),
          operator: _linkRatingOperator,
          onChanged: (value) {
            setState(() {
              _selectedLinkRating = value;
            });
          },
          onOperatorChanged: (value) {
            setState(() => _linkRatingOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildNumericInputWithOperator(
          label: 'ATK',
          controller: _atkController,
          operator: _atkOperator,
          onOperatorChanged: (value) {
            setState(() => _atkOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildNumericInputWithOperator(
          label: 'DEF',
          controller: _defController,
          operator: _defOperator,
          onOperatorChanged: (value) {
            setState(() => _defOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'TCG Bannliste',
                value: _selectedBanlistTCG,
                items: _banlistStatuses,
                onChanged: (value) =>
                    setState(() => _selectedBanlistTCG = value),
              ),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: _buildDropdown(
                label: 'OCG Bannliste',
                value: _selectedBanlistOCG,
                items: _banlistStatuses,
                onChanged: (value) =>
                    setState(() => _selectedBanlistOCG = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownWithOperator({
    required String label,
    required String? value,
    required List<String> items,
    required String operator,
    required void Function(String?) onChanged,
    required void Function(String?) onOperatorChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            value: operator,
            items: _operators.map((op) {
              return DropdownMenuItem<String>(
                value: op,
                child: Text(op, textAlign: TextAlign.center),
              );
            }).toList(),
            onChanged: onOperatorChanged,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              iconColor: Colors.white,
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            value: value,
            items: [
              DropdownMenuItem<String>(value: null, child: Text(label)),
              ...items.map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildNumericInputWithOperator({
    required String label,
    required TextEditingController controller,
    required String operator,
    required void Function(String?) onOperatorChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            value: operator,
            items: _operators.map((op) {
              return DropdownMenuItem<String>(
                value: op,
                child: Text(op, textAlign: TextAlign.center),
              );
            }).toList(),
            onChanged: onOperatorChanged,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        iconColor: Theme.of(context).textTheme.bodyMedium!.color,
        hintText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      items: [
        DropdownMenuItem<String>(value: null, child: Text(label)),
        ...items.map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildCardDetail() {
    return CardDetailView(
      cardData: _selectedCard!,
      onBack: () {
        setState(() {
          _selectedCard = null;
        });
      },
    );
  }
}
