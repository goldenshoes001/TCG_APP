// meta.dart - AKTUALISIERT MIT DECKVIEWER
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/DeckSearchView.dart'; // WIEDER EINGEFÜGT
import 'package:tcg_app/class/widgets/helperClass%20allgemein/search_results_view.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/widgets/deck_viewer.dart';

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

    // ACHTUNG: Das globale Suchfeld ist jetzt nur für Tab 0 sichtbar.
    // Daher sollte hier nur noch die Kartensuche ausgelöst werden.
    if (_tabController.index == 0) {
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
    }
    // Der ELSE-Block (Deck-Suche) ist nicht mehr nötig, da das Feld nur in Tab 0 existiert
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

  // Die _buildDeckResults() ist für die Ergebnisse des *globalen* Suchfeldes und
  // ist in dieser Logik nicht mehr relevant, da wir DeckSearchView verwenden.
  // Ich lasse sie, falls sie woanders benötigt wird, aber sie wird hier nicht mehr aufgerufen.

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_selectedCard != null) {
      return _buildCardDetail();
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
              // Der Suchfeld-Text bleibt im Controller, aber die onSubmitted-Logik ist auf Tab 0 beschränkt
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

                // GEÄNDERT: Bedingte Anzeige des globalen Suchfelds
                if (_tabController.index == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Karte suchen...", // Angepasster Hint
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        onSubmitted: _performTextSearch,
                        controller: _suchfeld,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 55),
                    ],
                  ),

                // ENDE: Bedingte Anzeige
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
                      // TAB 1: KARTEN (Bleibt gleich)
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

                      // TAB 2: DECKS (Wiederhergestellt)
                      const DeckSearchView(), // Das Suchfeld ist hier intern im Widget enthalten
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
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              iconColor: Theme.of(context).textTheme.bodyMedium!.color,
              hintText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
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
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                horizontal: 8,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
