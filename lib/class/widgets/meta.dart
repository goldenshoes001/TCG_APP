// meta.dart (MIT LEVEL-OPERATOR SUPPORT UND IMAGE CACHING)

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class//Imageloader.dart';

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

class _MetaState extends State<Meta> {
  final CardData _cardData = CardData();
  Future<List<Map<String, dynamic>>>? _searchFuture;
  Map<String, dynamic>? _selectedCard;
  bool _showFilters = true;

  final TextEditingController _suchfeld = TextEditingController();

  // Filter-Werte
  String? _selectedType;
  String? _selectedRace;
  String? _selectedAttribute;
  String? _selectedArchetype;
  String? _selectedBanlistTCG;
  String? _selectedBanlistOCG;

  // Listen für dynamisch geladene Filter-Werte
  List<String> _types = [];
  List<String> _races = [];
  List<String> _attributes = [];
  List<String> _archetypes = [];

  bool _filtersLoading = true;

  final TextEditingController _atkController = TextEditingController();
  final TextEditingController _defController = TextEditingController();
  final TextEditingController _scaleController = TextEditingController();
  final TextEditingController _linkRatingController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();

  String _atkOperator = '=';
  String _defOperator = '=';
  String _scaleOperator = '=';
  String _linkRatingOperator = '=';
  String _levelOperator = '=';

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    // Nutze vorgeladene Daten wenn verfügbar
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

    // Fallback: Lade Daten neu falls nicht vorgeladen
    if (mounted) {
      setState(() {
        _filtersLoading = true;
      });
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
        setState(() {
          _filtersLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _suchfeld.dispose();
    _atkController.dispose();
    _defController.dispose();
    _scaleController.dispose();
    _linkRatingController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  final List<String> _banlistStatuses = [
    'Forbidden',
    'Limited',
    'Semi-Limited',
  ];

  final List<String> _operators = ['min', '=', 'max'];

  void _resetFiltersState() {
    _selectedType = null;
    _selectedRace = null;
    _selectedAttribute = null;
    _selectedArchetype = null;
    _selectedBanlistTCG = null;
    _selectedBanlistOCG = null;
    _suchfeld.clear();
    _atkController.clear();
    _defController.clear();
    _scaleController.clear();
    _linkRatingController.clear();
    _levelController.clear();
    _atkOperator = '=';
    _defOperator = '=';
    _scaleOperator = '=';
    _linkRatingOperator = '=';
    _levelOperator = '=';
  }

  void _performSearch() {
    if (_selectedType == null &&
        _selectedRace == null &&
        _selectedAttribute == null &&
        _selectedArchetype == null &&
        _levelController.text.trim().isEmpty &&
        _atkController.text.trim().isEmpty &&
        _defController.text.trim().isEmpty &&
        _scaleController.text.trim().isEmpty &&
        _linkRatingController.text.trim().isEmpty &&
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
    if (_scaleController.text.trim().isNotEmpty) {
      scaleValue = int.tryParse(_scaleController.text.trim());
      scaleOperatorValue = _scaleOperator;
    }
    if (_linkRatingController.text.trim().isNotEmpty) {
      linkRatingValue = int.tryParse(_linkRatingController.text.trim());
      linkRatingOperatorValue = _linkRatingOperator;
    }
    if (_levelController.text.trim().isNotEmpty) {
      levelValue = int.tryParse(_levelController.text.trim());
      levelOperatorValue = _levelOperator;
    }

    setState(() {
      _searchFuture = _cardData.searchWithFilters(
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
      );
      _selectedCard = null;
      _showFilters = false;
    });
  }

  void _resetFilters() {
    _resetFiltersState();
    setState(() {
      _searchFuture = null;
      _selectedCard = null;
      _showFilters = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCard != null) {
      return _buildCardDetail();
    }

    if (_filtersLoading) {
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

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 350),

          TextField(
            decoration: const InputDecoration(
              hintText: "Suchen...",
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              final trimmedValue = _suchfeld.text.trim();
              if (trimmedValue.isNotEmpty) {
                _resetFiltersState();

                setState(() {
                  _searchFuture = _cardData
                      .ergebniseAnzeigen(trimmedValue)
                      .then((list) => list.cast<Map<String, dynamic>>());
                  _selectedCard = null;
                  _showFilters = false;
                });
              } else {
                setState(() {
                  _searchFuture = Future.value([]);
                  _selectedCard = null;
                  _showFilters = true;
                });
              }
            },
            controller: _suchfeld,
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 55),

          if (!_showFilters && _searchFuture != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _resetFiltersState();
                      setState(() {
                        _showFilters = true;
                        _searchFuture = null;
                      });
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter anzeigen'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _showFilters
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterGrid(),

                        SizedBox(
                          height: MediaQuery.of(context).size.height / 40,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _performSearch,
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
                : SingleChildScrollView(child: _buildSearchResults()),
          ),
        ],
      ),
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
          value: _levelController.text.isEmpty ? null : _levelController.text,
          items: List.generate(13, (index) => index.toString()),
          operator: _levelOperator,
          onChanged: (value) {
            setState(() {
              if (value != null && value.isNotEmpty) {
                _levelController.text = value;
              } else {
                _levelController.clear();
              }
            });
          },
          onOperatorChanged: (value) {
            setState(() => _levelOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildDropdownWithOperator(
          label: 'Scale',
          value: _scaleController.text.isEmpty ? null : _scaleController.text,
          items: List.generate(14, (index) => index.toString()),
          operator: _scaleOperator,
          onChanged: (value) {
            setState(() {
              if (value != null && value.isNotEmpty) {
                _scaleController.text = value;
              } else {
                _scaleController.clear();
              }
            });
          },
          onOperatorChanged: (value) {
            setState(() => _scaleOperator = value!);
          },
        ),
        const SizedBox(height: spacing),

        _buildDropdownWithOperator(
          label: 'Link Rating',
          value: _linkRatingController.text.isEmpty
              ? null
              : _linkRatingController.text,
          items: List.generate(8, (index) => (index + 1).toString()),
          operator: _linkRatingOperator,
          onChanged: (value) {
            setState(() {
              if (value != null && value.isNotEmpty) {
                _linkRatingController.text = value;
              } else {
                _linkRatingController.clear();
              }
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
        SizedBox(
          width: 70,
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
        SizedBox(
          width: 70,
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

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (_searchFuture == null) {
          return Center(
            child: Text(
              'Geben Sie einen Suchbegriff ein oder wählen Sie Filter aus.',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Laden...', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Fehler beim Laden: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: const Text(
                'Keine Karten gefunden.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cards.length} Karte(n) gefunden',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final cardName = card["name"] ?? 'Unbekannte Karte';

                final List<dynamic>? cardImagesDynamic = card["card_images"];
                String imageUrl = '';

                if (cardImagesDynamic != null && cardImagesDynamic.isNotEmpty) {
                  if (cardImagesDynamic[0] is Map<String, dynamic>) {
                    imageUrl = cardImagesDynamic[0]['image_url'] ?? '';
                  }
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCard = card;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 50,
                          height: 70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            cardName,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
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
