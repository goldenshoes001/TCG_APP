// card_search_dialog.dart - Updated to DropdownMenu
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class CardSearchDialog extends StatefulWidget {
  final Function(Map<String, dynamic> card, int count) onCardSelected;
  final bool isSideDeck;
  final Function(String message)? onShowSnackBar;

  const CardSearchDialog({
    super.key,
    required this.onCardSelected,
    this.isSideDeck = false,
    this.onShowSnackBar,
  });

  @override
  State<CardSearchDialog> createState() => _CardSearchDialogState();
}

class _CardSearchDialogState extends State<CardSearchDialog> {
  final CardData _cardData = CardData();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _searchFuture;
  int dropdownResetkey = 0;

  bool _showFilters = false;
  bool _filtersLoading = true;

  // Filter-Werte
  String? _selectedType;
  String? _selectedRace;
  String? _selectedAttribute;
  String? _selectedArchetype;
  String? _selectedLevel;
  String? _selectedScale;
  String? _selectedLinkRating;

  // Listen für Filter
  List<String> _types = [];
  List<String> _races = [];
  List<String> _attributes = [];
  List<String> _archetypes = [];

  // Operatoren
  String _levelOperator = '=';
  String _scaleOperator = '=';
  String _linkRatingOperator = '=';
  final List<String> _operators = ['min', '=', 'max'];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterData() async {
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

  void _performTextSearch(String query) {
    final trimmedValue = query.trim();
    if (trimmedValue.isNotEmpty) {
      setState(() {
        _searchFuture = _cardData.ergebniseAnzeigen(trimmedValue).then((
          list,
        ) async {
          final cards = list.cast<Map<String, dynamic>>();
          final filteredCards = cards.where((card) {
            final frameType = (card['frameType'] as String? ?? '')
                .toLowerCase();
            return frameType != 'token' && frameType != 'skill';
          }).toList();
          await _cardData.preloadCardImages(filteredCards);
          return filteredCards;
        });
        _showFilters = false;
      });
    } else {
      setState(() {
        _searchFuture = Future.value([]);
      });
    }
  }

  void _performFilterSearch() {
    // VALIDIERUNG: Mindestens ein Filter muss ausgewählt sein
    if (_selectedType == null &&
        _selectedRace == null &&
        _selectedAttribute == null &&
        _selectedArchetype == null &&
        _selectedLevel == null &&
        _selectedScale == null &&
        _selectedLinkRating == null) {
      ScaffoldMessenger.of(Overlay.of(context).context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wählen Sie mindestens einen Filter aus.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      return; // Abbrechen, wenn keine Filter gesetzt sind
    }

    int? levelValue;
    String? levelOperatorValue;
    int? scaleValue;
    String? scaleOperatorValue;
    int? linkRatingValue;
    String? linkRatingOperatorValue;

    if (_selectedLevel != null) {
      levelValue = int.tryParse(_selectedLevel!);
      levelOperatorValue = _levelOperator;
    }
    if (_selectedScale != null) {
      scaleValue = int.tryParse(_selectedScale!);
      scaleOperatorValue = _scaleOperator;
    }
    if (_selectedLinkRating != null) {
      linkRatingValue = int.tryParse(_selectedLinkRating!);
      linkRatingOperatorValue = _linkRatingOperator;
    }

    setState(() {
      _searchFuture = _cardData
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
          )
          .then((list) async {
            final cards = list.cast<Map<String, dynamic>>();
            final filteredCards = cards.where((card) {
              final frameType = (card['frameType'] as String? ?? '')
                  .toLowerCase();
              return frameType != 'token' && frameType != 'skill';
            }).toList();
            await _cardData.preloadCardImages(filteredCards);
            return filteredCards;
          });
      _showFilters = false;
    });
  }

  void _resetFilters() {
    setState(() {
      // Alle Filter auf Standardwerte zurücksetzen
      _selectedType = null;
      _selectedRace = null;
      _selectedAttribute = null;
      _selectedArchetype = null;
      _selectedLevel = null;
      _selectedScale = null;
      _selectedLinkRating = null;

      // Operatoren auf Standardwert zurücksetzen
      _levelOperator = '=';
      _scaleOperator = '=';
      _linkRatingOperator = '=';
      dropdownResetkey++;
    });

    // Erfolgsmeldung anzeigen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter wurden zurückgesetzt'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  int _getMaxAllowedCount(Map<String, dynamic> card) {
    final banlistInfo = card['banlist_info'];
    if (banlistInfo == null) return 3;

    final tcgBan = banlistInfo['ban_tcg'] as String?;

    if (tcgBan == 'Forbidden') return 0;
    if (tcgBan == 'Limited') return 1;
    if (tcgBan == 'Semi-Limited') return 2;

    return 3;
  }

  void _showCardCountDialog(Map<String, dynamic> card) {
    final maxCount = _getMaxAllowedCount(card);

    if (maxCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card['name']} ist verboten und kann nicht hinzugefügt werden.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wie oft hinzufügen?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card['name'] ?? 'Unbekannte Karte'),
              const SizedBox(height: 16),
              if (maxCount < 3)
                Text(
                  'Diese Karte ist ${maxCount == 1 ? 'limitiert' : 'semi-limitiert'}',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ...List.generate(maxCount, (index) {
              final count = index + 1;
              return TextButton(
                onPressed: () {
                  widget.onCardSelected(card, count);
                  Navigator.of(context).pop();
                },
                child: Text('${count}x'),
              );
            }),
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
    return DropdownMenu<String>(
      label: Text(label),
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: items.map((item) {
        return DropdownMenuEntry<String>(value: item, label: item);
      }).toList(),
      onSelected: onChanged,
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
          child: DropdownMenu<String>(
            initialSelection: operator,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: _operators.map((op) {
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

  Widget _buildFilterSection() {
    if (_filtersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    const double spacing = 12.0;

    return SingleChildScrollView(
      child: Column(
        key: ValueKey(dropdownResetkey),
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            onChanged: (value) => setState(() => _selectedLevel = value),
            onOperatorChanged: (value) =>
                setState(() => _levelOperator = value!),
          ),
          const SizedBox(height: spacing),
          _buildDropdownWithOperator(
            label: 'Scale',
            value: _selectedScale,
            items: List.generate(14, (index) => index.toString()),
            operator: _scaleOperator,
            onChanged: (value) => setState(() => _selectedScale = value),
            onOperatorChanged: (value) =>
                setState(() => _scaleOperator = value!),
          ),
          const SizedBox(height: spacing),
          _buildDropdownWithOperator(
            label: 'Link Rating',
            value: _selectedLinkRating,
            items: List.generate(6, (index) => (index + 1).toString()),
            operator: _linkRatingOperator,
            onChanged: (value) => setState(() => _selectedLinkRating = value),
            onOperatorChanged: (value) =>
                setState(() => _linkRatingOperator = value!),
          ),
          const SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _performFilterSearch,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100.0),
      child: Dialog(
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Filter Search'),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.search : Icons.filter_list,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!_showFilters) ...[
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Cardname...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _performTextSearch,
                    ),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: _showFilters
                        ? _buildFilterSection()
                        : _searchFuture == null
                        ? Center(
                            child: Text(
                              'Gib einen Kartennamen ein oder nutze die Filter',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : FutureBuilder<List<Map<String, dynamic>>>(
                            future: _searchFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Fehler: ${snapshot.error}'),
                                );
                              }

                              final cards = snapshot.data ?? [];

                              if (cards.isEmpty) {
                                return const Center(
                                  child: Text('Keine Karten gefunden'),
                                );
                              }

                              return ListView.builder(
                                itemCount: cards.length,
                                itemBuilder: (context, index) {
                                  final card = cards[index];

                                  return Card(
                                    child: ListTile(
                                      leading: _CardImageWidget(
                                        card: card,
                                        cardData: _cardData,
                                      ),
                                      title: Text(card['name'] ?? 'Unbekannt'),

                                      onTap: () => _showCardCountDialog(card),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImageWidget extends StatefulWidget {
  final Map<String, dynamic> card;
  final CardData cardData;

  const _CardImageWidget({required this.card, required this.cardData});

  @override
  State<_CardImageWidget> createState() => _CardImageWidgetState();
}

class _CardImageWidgetState extends State<_CardImageWidget> {
  String? _loadedImageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_CardImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card != oldWidget.card) {
      _loadedImageUrl = null;
      _isLoading = true;
      _hasError = false;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final cardImages = widget.card['card_images'] as List<dynamic>?;

    if (cardImages == null || cardImages.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    final List<String> allImageUrls = [];

    for (var imageEntry in cardImages) {
      if (imageEntry is Map<String, dynamic>) {
        final normalUrl = imageEntry['image_url'] as String?;
        if (normalUrl != null && normalUrl.isNotEmpty) {
          allImageUrls.add(normalUrl);
        }

        final croppedUrl = imageEntry['image_url_cropped'] as String?;
        if (croppedUrl != null && croppedUrl.isNotEmpty) {
          allImageUrls.add(croppedUrl);
        }

        final smallUrl = imageEntry['image_url_small'] as String?;
        if (smallUrl != null && smallUrl.isNotEmpty) {
          allImageUrls.add(smallUrl);
        }
      }
    }

    for (var imageUrl in allImageUrls) {
      try {
        final downloadUrl = await widget.cardData.getImgPath(imageUrl);

        if (downloadUrl.isNotEmpty && mounted) {
          setState(() {
            _loadedImageUrl = downloadUrl;
            _isLoading = false;
            _hasError = false;
          });
          return;
        }
      } catch (e) {
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _loadedImageUrl == null || _loadedImageUrl!.isEmpty) {
      return const SizedBox(
        width: 40,
        height: 60,
        child: Icon(Icons.image_not_supported, size: 30),
      );
    }

    return Image.network(
      _loadedImageUrl!,
      width: 40,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 40,
          height: 60,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          width: 40,
          height: 60,
          child: Icon(Icons.broken_image, size: 30, color: Colors.red),
        );
      },
    );
  }
}
