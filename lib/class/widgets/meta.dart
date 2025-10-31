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
  int? _selectedLevel;
  int? _selectedLinkRating;
  int? _selectedScale;
  String? _selectedAtk;
  String? _selectedDef;
  String? _selectedBanlistTCG;
  String? _selectedBanlistOCG;

  @override
  void dispose() {
    _suchfeld.dispose();
    super.dispose();
  }

  // Alphabetisch sortierte Listen
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

  final List<String> _atkDefValues = [
    '0',
    '100',
    '200',
    '300',
    '400',
    '500',
    '600',
    '700',
    '800',
    '900',
    '1000',
    '1100',
    '1200',
    '1300',
    '1400',
    '1500',
    '1600',
    '1700',
    '1800',
    '1900',
    '2000',
    '2100',
    '2200',
    '2300',
    '2400',
    '2500',
    '2600',
    '2700',
    '2800',
    '2900',
    '3000',
    '3500',
    '4000',
    '?',
  ];

  void _resetFiltersState() {
    _selectedType = null;
    _selectedRace = null;
    _selectedAttribute = null;
    _selectedLevel = null;
    _selectedLinkRating = null;
    _selectedScale = null;
    _selectedAtk = null;
    _selectedDef = null;
    _selectedBanlistTCG = null;
    _selectedBanlistOCG = null;
    _suchfeld.clear();
  }

  void _performSearch() {
    if (_selectedType == null &&
        _selectedRace == null &&
        _selectedAttribute == null &&
        _selectedLevel == null &&
        _selectedLinkRating == null &&
        _selectedScale == null &&
        _selectedAtk == null &&
        _selectedDef == null &&
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

    setState(() {
      _searchFuture = _cardData.searchWithFilters(
        type: _selectedType,
        race: _selectedRace,
        attribute: _selectedAttribute,
        level: _selectedLevel,
        linkRating: _selectedLinkRating,
        scale: _selectedScale,
        atk: _selectedAtk,
        def: _selectedDef,
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
    // Wenn eine Karte ausgewählt ist, gib nur die CardDetailView zurück
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
                    Text(
                      'Kartensuche nach Eigenschaften',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 55),

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
    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 12.0;
        final double itemWidthTwoColumns = (constraints.maxWidth - spacing) / 2;

        Widget buildSizedDropdown({
          required Widget child,
          required double width,
        }) {
          final double finalWidth = width > 0 ? width : constraints.maxWidth;
          return SizedBox(width: finalWidth, child: child);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: spacing),
              child: buildSizedDropdown(
                width: constraints.maxWidth,
                child: _buildDropdown(
                  label: 'Type',
                  value: _selectedType,
                  items: _types,
                  onChanged: (value) => setState(() => _selectedType = value),
                ),
              ),
            ),

            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'Race',
                    value: _selectedRace,
                    items: _races,
                    onChanged: (value) => setState(() => _selectedRace = value),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'Attribut',
                    value: _selectedAttribute,
                    items: _attributes,
                    onChanged: (value) =>
                        setState(() => _selectedAttribute = value),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'Level',
                    value: _selectedLevel?.toString(),
                    items: List.generate(13, (index) => index.toString()),
                    onChanged: (value) => setState(
                      () => _selectedLevel = value != null && value.isNotEmpty
                          ? int.tryParse(value)
                          : null,
                    ),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'Link Rating',
                    value: _selectedLinkRating?.toString(),
                    items: List.generate(8, (index) => (index + 1).toString()),
                    onChanged: (value) => setState(
                      () => _selectedLinkRating =
                          value != null && value.isNotEmpty
                          ? int.tryParse(value)
                          : null,
                    ),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'Scale',
                    value: _selectedScale?.toString(),
                    items: List.generate(14, (index) => index.toString()),
                    onChanged: (value) => setState(
                      () => _selectedScale = value != null && value.isNotEmpty
                          ? int.tryParse(value)
                          : null,
                    ),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'ATK',
                    value: _selectedAtk,
                    items: _atkDefValues,
                    onChanged: (value) => setState(() => _selectedAtk = value),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'DEF',
                    value: _selectedDef,
                    items: _atkDefValues,
                    onChanged: (value) => setState(() => _selectedDef = value),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
                  child: _buildDropdown(
                    label: 'TCG Bannliste',
                    value: _selectedBanlistTCG,
                    items: _banlistStatuses,
                    onChanged: (value) =>
                        setState(() => _selectedBanlistTCG = value),
                  ),
                ),
                buildSizedDropdown(
                  width: itemWidthTwoColumns,
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
      },
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
