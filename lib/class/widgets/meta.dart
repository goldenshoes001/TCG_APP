import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';

class Meta extends StatefulWidget {
  const Meta({super.key});

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
  int? _selectedLevel;
  String? _selectedBanlistTCG;
  String? _selectedBanlistOCG;

  // NEU: Liste für dynamisch geladene Archetypen
  List<String> _archetypes = [];
  bool _archetypesLoading = true;

  final TextEditingController _atkController = TextEditingController();
  final TextEditingController _defController = TextEditingController();
  final TextEditingController _scaleController = TextEditingController();
  final TextEditingController _linkRatingController = TextEditingController();

  String _atkOperator = '=';
  String _defOperator = '=';
  String _scaleOperator = '=';
  String _linkRatingOperator = '=';

  @override
  void initState() {
    super.initState();
    _loadArchetypes();
  }

  // NEU: Archetypen aus Algolia laden
  Future<void> _loadArchetypes() async {
    try {
      final archetypes = await _cardData.getAllArchetypes();
      setState(() {
        _archetypes = archetypes;
        _archetypesLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Archetypen: $e');
      setState(() {
        _archetypesLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _suchfeld.dispose();
    _atkController.dispose();
    _defController.dispose();
    _scaleController.dispose();
    _linkRatingController.dispose();
    super.dispose();
  }

  final List<String> _types = [
    'Effect Monster',
    'Flip Monster',
    'Fusion Monster',
    'Gemini Monster',
    'Link Monster',
    'Normal Monster',
    'Pendulum',
    'Ritual Monster',
    'Skill Card',
    'Spell Card',
    'Spirit Monster',
    'Synchro Monster',
    'Token',
    'Toon Monster',
    'Trap Card',
    'Tuner Monster',
    'Union Effect Monster',
    'XYZ Monster',
  ]..sort();

  final List<String> _races = [
    'Aqua',
    'Beast',
    'Beast-Warrior',
    'Continuous',
    'Counter',
    'Creator God',
    'Cyberse',
    'Dinosaur',
    'Divine-Beast',
    'Dragon',
    'Equip',
    'Fairy',
    'Field',
    'Fiend',
    'Fish',
    'Illusion',
    'Insect',
    'Machine',
    'Normal',
    'Plant',
    'Psychic',
    'Pyro',
    'Quick-Play',
    'Reptile',
    'Ritual',
    'Rock',
    'Sea Serpent',
    'Spellcaster',
    'Thunder',
    'Warrior',
    'Winged Beast',
    'Wyrm',
    'Zombie',
  ]..sort();

  final List<String> _attributes = [
    'DARK',
    'DIVINE',
    'EARTH',
    'FIRE',
    'LIGHT',
    'WATER',
    'WIND',
  ]..sort();

  final List<String> _banlistStatuses = [
    'Forbidden',
    'Limited',
    'Semi-Limited',
  ];

  final List<String> _operators = ['=', '>=', '<='];

  void _resetFiltersState() {
    _selectedType = null;
    _selectedRace = null;
    _selectedAttribute = null;
    _selectedArchetype = null;
    _selectedLevel = null;
    _selectedBanlistTCG = null;
    _selectedBanlistOCG = null;
    _suchfeld.clear();
    _atkController.clear();
    _defController.clear();
    _scaleController.clear();
    _linkRatingController.clear();
    _atkOperator = '=';
    _defOperator = '=';
    _scaleOperator = '=';
    _linkRatingOperator = '=';
  }

  void _performSearch() {
    if (_selectedType == null &&
        _selectedRace == null &&
        _selectedAttribute == null &&
        _selectedArchetype == null &&
        _selectedLevel == null &&
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

    if (_atkController.text.trim().isNotEmpty) {
      atkFilter = '${_atkOperator}${_atkController.text.trim()}';
    }
    if (_defController.text.trim().isNotEmpty) {
      defFilter = '${_defOperator}${_defController.text.trim()}';
    }
    if (_scaleController.text.trim().isNotEmpty) {
      scaleValue = int.tryParse(_scaleController.text.trim());
      scaleOperatorValue = _scaleOperator;
    }
    if (_linkRatingController.text.trim().isNotEmpty) {
      linkRatingValue = int.tryParse(_linkRatingController.text.trim());
      linkRatingOperatorValue = _linkRatingOperator;
    }

    setState(() {
      _searchFuture = _cardData.searchWithFilters(
        type: _selectedType,
        race: _selectedRace,
        attribute: _selectedAttribute,
        archetype: _selectedArchetype,
        level: _selectedLevel,
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

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.height / 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height / 350),

          TextField(
            decoration: InputDecoration(
              hintText: "Suchen...",
              prefixIcon: const Icon(Icons.search),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showFilters) ...[
                    _buildFilterGrid(),

                    SizedBox(height: MediaQuery.of(context).size.height / 40),

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

                    SizedBox(height: MediaQuery.of(context).size.height / 40),
                  ],

                  if (!_showFilters) _buildSearchResults(),
                ],
              ),
            ),
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

        // NEU: Archetype mit Loading-Indikator
        _archetypesLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _buildDropdown(
                label: 'Archetyp',
                value: _selectedArchetype,
                items: _archetypes,
                onChanged: (value) =>
                    setState(() => _selectedArchetype = value),
              ),
        const SizedBox(height: spacing),

        _buildDropdown(
          label: 'Level',
          value: _selectedLevel?.toString(),
          items: List.generate(13, (index) => index.toString()),
          onChanged: (value) => setState(
            () => _selectedLevel = value != null && value.isNotEmpty
                ? int.tryParse(value)
                : null,
          ),
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
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
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
        iconColor: Colors.white,
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

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (_searchFuture == null) {
          return const Center(
            child: Text(
              'Geben Sie einen Suchbegriff ein oder wählen Sie Filter aus.',
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Fehler beim Laden: ${snapshot.error}'));
        }

        final cards = snapshot.data;

        if (cards == null || cards.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Keine Karten gefunden.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cards.length} Karte(n) gefunden'),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final cardName = card["name"] ?? 'Unbekannte Karte';

                final List<dynamic>? cardImagesDynamic = card["card_images"];
                final List<String> cardImages = [];

                if (cardImagesDynamic != null) {
                  for (var imageObj in cardImagesDynamic) {
                    if (imageObj is Map<String, dynamic>) {
                      final imageUrl =
                          imageObj['image_url'] ??
                          imageObj['image_url_cropped'] ??
                          '';
                      if (imageUrl.isNotEmpty) {
                        cardImages.add(imageUrl.toString());
                      }
                    }
                  }
                }

                Future<String> imageUrlFuture = _cardData.getCorrectImgPath(
                  cardImages,
                );

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
                        FutureBuilder<String>(
                          future: imageUrlFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 50,
                                height: 70,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            } else if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox(
                                width: 50,
                                height: 70,
                                child: Icon(Icons.broken_image),
                              );
                            } else {
                              return Image.network(
                                snapshot.data!,
                                height: 70,
                                width: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    width: 50,
                                    height: 70,
                                    child: Icon(Icons.broken_image),
                                  );
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 15),
                        Expanded(child: Text(cardName)),
                        const Icon(Icons.chevron_right, color: Colors.grey),
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
