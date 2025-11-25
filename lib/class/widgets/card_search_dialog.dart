// card_search_dialog.dart - UPDATED WITH SAME FILTERS AS SEARCH.DART
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
  final TextEditingController _atkController = TextEditingController();
  final TextEditingController _defController = TextEditingController();

  Future<List<Map<String, dynamic>>>? _searchFuture;
  int dropdownResetkey = 0;

  bool _showFilters = false;
  bool _filtersLoading = true;

  // Filter-Werte (wie in search.dart)
  String? _selectedType;
  String? _selectedRace;
  String? _selectedAttribute;
  String? _selectedArchetype;
  String? _selectedLevel;
  String? _selectedScale;
  String? _selectedLinkRating;
  String? _selectedBanlistTCG;
  String? _selectedBanlistOCG;

  // Listen für Filter
  List<String> _types = [];
  List<String> _races = [];
  List<String> _attributes = [];
  List<String> _archetypes = [];

  // Operatoren (wie in search.dart)
  String _atkOperator = '=';
  String _defOperator = '=';
  String _levelOperator = '=';
  String _scaleOperator = '=';
  String _linkRatingOperator = '=';
  final List<String> _operators = ['min', '=', 'max'];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
    _atkController.addListener(_onTextFieldChanged);
    _defController.addListener(_onTextFieldChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _atkController.removeListener(_onTextFieldChanged);
    _defController.removeListener(_onTextFieldChanged);
    _atkController.dispose();
    _defController.dispose();
    super.dispose();
  }

  void _onTextFieldChanged() {
    setState(() {});
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
      print('Error on loading filters: $e');
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
    final hasQuery = _searchController.text.trim().isNotEmpty;

    final hasFilters =
        _selectedType != null ||
        _selectedRace != null ||
        _selectedAttribute != null ||
        _selectedArchetype != null ||
        _selectedLevel != null ||
        _atkController.text.trim().isNotEmpty ||
        _defController.text.trim().isNotEmpty ||
        _selectedScale != null ||
        _selectedLinkRating != null ||
        _selectedBanlistTCG != null ||
        _selectedBanlistOCG != null;

    if (!hasQuery && !hasFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose at least one filter.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int? levelValue;
    String? levelOperatorValue;
    int? scaleValue;
    String? scaleOperatorValue;
    int? linkRatingValue;
    String? linkRatingOperatorValue;
    String? atkFilter;
    String? defFilter;

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

    setState(() {
      _searchFuture = _cardData
          .searchWithQueryAndFilters(
            query: hasQuery ? _searchController.text.trim() : null,
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
      _selectedType = null;
      _selectedRace = null;
      _selectedAttribute = null;
      _selectedArchetype = null;
      _selectedLevel = null;
      _selectedScale = null;
      _selectedLinkRating = null;
      _selectedBanlistTCG = null;
      _selectedBanlistOCG = null;

      _atkOperator = '=';
      _defOperator = '=';
      _levelOperator = '=';
      _scaleOperator = '=';
      _linkRatingOperator = '=';

      _atkController.clear();
      _defController.clear();
      _searchController.clear();

      dropdownResetkey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters reset'),
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
          content: Text('${card['name']} is forbidden and cannot be added.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How many copies to add?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card['name'] ?? 'Unknown Card'),
              const SizedBox(height: 16),
              if (maxCount < 3)
                Text(
                  'This card is ${maxCount == 1 ? 'limited' : 'semi-limited'}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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

  Widget _buildFilterForm() {
    if (_filtersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    const double spacing = 12.0;
    const activeColor = Colors.lightBlue;
    final List<String> banlistStatuses = [
      'Forbidden',
      'Limited',
      'Semi-Limited',
    ];

    return SingleChildScrollView(
      child: Column(
        key: ValueKey(dropdownResetkey),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Type Dropdown
          DropdownMenu<String>(
            label: null,
            textStyle: TextStyle(
              color: _selectedType != null ? activeColor : null,
            ),
            initialSelection: _selectedType ?? 'Type',
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String>(value: 'Type', label: 'Type'),
              ..._types.map(
                (item) => DropdownMenuEntry<String>(value: item, label: item),
              ),
            ],
            onSelected: (value) {
              setState(() => _selectedType = value == 'Type' ? null : value);
            },
          ),
          const SizedBox(height: spacing),

          // Race & Attribute Row
          Row(
            children: [
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: _selectedRace != null ? activeColor : null,
                  ),
                  initialSelection: _selectedRace ?? 'Race',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'Race',
                      label: 'Race',
                    ),
                    ..._races.map(
                      (item) =>
                          DropdownMenuEntry<String>(value: item, label: item),
                    ),
                  ],
                  onSelected: (value) {
                    setState(
                      () => _selectedRace = value == 'Race' ? null : value,
                    );
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: _selectedAttribute != null ? activeColor : null,
                  ),
                  initialSelection: _selectedAttribute ?? 'Attribut',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'Attribut',
                      label: 'Attribut',
                    ),
                    ..._attributes.map(
                      (item) =>
                          DropdownMenuEntry<String>(value: item, label: item),
                    ),
                  ],
                  onSelected: (value) {
                    setState(
                      () => _selectedAttribute = value == 'Attribut'
                          ? null
                          : value,
                    );
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
              color: _selectedArchetype != null ? activeColor : null,
            ),
            initialSelection: _selectedArchetype ?? 'All archetypes',
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String>(
                value: 'All archetypes',
                label: 'All archetypes',
              ),
              ..._archetypes.map(
                (item) => DropdownMenuEntry<String>(value: item, label: item),
              ),
            ],
            onSelected: (value) {
              setState(
                () => _selectedArchetype = value == 'All archetypes'
                    ? null
                    : value,
              );
            },
          ),
          const SizedBox(height: spacing),

          // Level with Operator
          _buildOperatorDropdown(
            label: 'Level',
            value: _selectedLevel,
            items: List.generate(14, (index) => index.toString()),
            operator: _levelOperator,
            onChanged: (value) => setState(
              () => _selectedLevel = value == 'Level' ? null : value,
            ),
            onOperatorChanged: (value) =>
                setState(() => _levelOperator = value!),
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // Scale with Operator
          _buildOperatorDropdown(
            label: 'Scale',
            value: _selectedScale,
            items: List.generate(14, (index) => index.toString()),
            operator: _scaleOperator,
            onChanged: (value) => setState(
              () => _selectedScale = value == 'Scale' ? null : value,
            ),
            onOperatorChanged: (value) =>
                setState(() => _scaleOperator = value!),
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // Link Rating with Operator
          _buildOperatorDropdown(
            label: 'Link Rating',
            value: _selectedLinkRating,
            items: List.generate(6, (index) => (index + 1).toString()),
            operator: _linkRatingOperator,
            onChanged: (value) => setState(
              () => _selectedLinkRating = value == 'Link Rating' ? null : value,
            ),
            onOperatorChanged: (value) =>
                setState(() => _linkRatingOperator = value!),
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // ATK with Operator
          _buildOperatorTextInput(
            label: 'ATK',
            controller: _atkController,
            operator: _atkOperator,
            onOperatorChanged: (value) => setState(() => _atkOperator = value!),
            activeColor: activeColor,
          ),
          const SizedBox(height: spacing),

          // DEF with Operator
          _buildOperatorTextInput(
            label: 'DEF',
            controller: _defController,
            operator: _defOperator,
            onOperatorChanged: (value) => setState(() => _defOperator = value!),
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
                    color: _selectedBanlistTCG != null ? activeColor : null,
                  ),
                  initialSelection: _selectedBanlistTCG ?? 'TCG Bannliste',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'TCG Bannliste',
                      label: 'TCG Bannliste',
                    ),
                    ...banlistStatuses.map(
                      (item) =>
                          DropdownMenuEntry<String>(value: item, label: item),
                    ),
                  ],
                  onSelected: (value) {
                    setState(
                      () => _selectedBanlistTCG = value == 'TCG Bannliste'
                          ? null
                          : value,
                    );
                  },
                ),
              ),
              const SizedBox(width: spacing),
              Expanded(
                child: DropdownMenu<String>(
                  label: null,
                  textStyle: TextStyle(
                    color: _selectedBanlistOCG != null ? activeColor : null,
                  ),
                  initialSelection: _selectedBanlistOCG ?? 'OCG Bannliste',
                  expandedInsets: EdgeInsets.zero,
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'OCG Bannliste',
                      label: 'OCG Bannliste',
                    ),
                    ...banlistStatuses.map(
                      (item) =>
                          DropdownMenuEntry<String>(value: item, label: item),
                    ),
                  ],
                  onSelected: (value) {
                    setState(
                      () => _selectedBanlistOCG = value == 'OCG Bannliste'
                          ? null
                          : value,
                    );
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
                  onPressed: _performFilterSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Reset'),
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
            label: null,
            textStyle: TextStyle(color: value != null ? activeColor : null),
            initialSelection: value ?? label,
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              DropdownMenuEntry<String>(value: label, label: label),
              ...items.map(
                (item) => DropdownMenuEntry<String>(value: item, label: item),
              ),
            ],
            onSelected: onChanged,
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
    return Row(
      children: [
        SizedBox(
          width: 80,
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
                      Text('Card Search'),
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
                        hintText: "Card name...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _performTextSearch,
                    ),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: _showFilters
                        ? _buildFilterForm()
                        : _searchFuture == null
                        ? Center(
                            child: Text(
                              'Enter a card name or use the filters',
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
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }

                              final cards = snapshot.data ?? [];

                              if (cards.isEmpty) {
                                return const Center(
                                  child: Text('No cards found'),
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
                                      title: Text(card['name'] ?? 'Unknown'),
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
