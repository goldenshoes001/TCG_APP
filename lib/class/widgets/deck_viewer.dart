// deck_viewer.dart - Verbesserte Bildlade-Logik
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ViewDeckType { main, extra, side }

class DeckViewer extends StatefulWidget {
  final Map<String, dynamic> deckData;
  final VoidCallback onBack;

  const DeckViewer({super.key, required this.deckData, required this.onBack});

  @override
  State<DeckViewer> createState() => _DeckViewerState();
}

class _DeckViewerState extends State<DeckViewer> {
  final CardData _cardData = CardData();
  final DeckService _deckService = DeckService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ViewDeckType _selectedDeckType = ViewDeckType.main;
  Map<String, dynamic>? _selectedCardForDetail;

  List<Map<String, dynamic>> get _mainDeck =>
      (widget.deckData['mainDeck'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get _extraDeck =>
      (widget.deckData['extraDeck'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ??
      [];

  List<Map<String, dynamic>> get _sideDeck =>
      (widget.deckData['sideDeck'] as List<dynamic>?)
          ?.map((item) => item as Map<String, dynamic>)
          .toList() ??
      [];

  void _showCardDetail(Map<String, dynamic> card) {
    setState(() {
      _selectedCardForDetail = card;
    });
  }

  Widget _buildDeckSection({
    required String title,
    required List<Map<String, dynamic>> deck,
  }) {
    if (deck.isEmpty) {
      return Center(
        child: Text(
          'Keine Karten im $title',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> categorized = {
      'Monster': [],
      'Spell': [],
      'Trap': [],
    };

    for (var card in deck) {
      final type = card['type'] as String? ?? '';
      if (type.contains('Monster')) {
        categorized['Monster']!.add(card);
      } else if (type.contains('Spell')) {
        categorized['Spell']!.add(card);
      } else if (type.contains('Trap')) {
        categorized['Trap']!.add(card);
      }
    }

    int getTotalCount(List<Map<String, dynamic>> cards) {
      return cards.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
    }

    Widget buildCategory(
      String categoryName,
      List<Map<String, dynamic>> cards,
    ) {
      if (cards.isEmpty) return const SizedBox.shrink();

      final totalCount = getTotalCount(cards);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              '$categoryName ($totalCount)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards.map((card) {
              final count = card['count'] as int? ?? 0;
              final name = card['name'] as String? ?? 'Unbekannt';

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: InkWell(
                  onTap: () => _showCardDetail(card),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            '${count}x',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CardImageWidget(card: card, cardData: _cardData),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCategory('Monster', categorized['Monster']!),
        buildCategory('Spell', categorized['Spell']!),
        buildCategory('Trap', categorized['Trap']!),
      ],
    );
  }

  Widget _buildDynamicDeckView() {
    ViewDeckType currentType = _selectedDeckType;
    String title;
    List<Map<String, dynamic>> deck;

    switch (currentType) {
      case ViewDeckType.main:
        title = 'Main Deck';
        deck = _mainDeck;
        break;
      case ViewDeckType.extra:
        title = 'Extra Deck';
        deck = _extraDeck;
        break;
      case ViewDeckType.side:
        title = 'Side Deck';
        deck = _sideDeck;
        break;
    }

    final totalCards = deck.fold(
      0,
      (sum, card) => sum + (card['count'] as int? ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
          child: Text(
            '$title ($totalCards Karten)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: _buildDeckSection(title: title, deck: deck),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCardForDetail != null) {
      return CardDetailView(
        cardData: _selectedCardForDetail!,
        onBack: () {
          setState(() {
            _selectedCardForDetail = null;
          });
        },
      );
    }

    final deckName = widget.deckData['deckName'] as String? ?? 'Unbekannt';
    final archetype = widget.deckData['archetype'] as String? ?? '';
    final description = widget.deckData['description'] as String? ?? '';
    final username = widget.deckData['username'] as String? ?? 'Unbekannt';
    final deckId = widget.deckData['deckId'] as String?;

    final dropdownItemStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyMedium!.color,
      fontSize: 14,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Header mit Zurück-Button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  deckName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Deck-Informationen
          if (archetype.isNotEmpty) ...[
            Text('Archetypen: $archetype'),
            const SizedBox(height: 4),
          ],
          Text('Von: $username'),
          const SizedBox(height: 8),

          if (description.isNotEmpty) ...[
            Text(
              'Beschreibung:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 16),
          ],

          // Dropdown Menü zur Auswahl des Decks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deck-Anzeige',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              DropdownButton<ViewDeckType>(
                value: _selectedDeckType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                onChanged: (ViewDeckType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDeckType = newValue;
                    });
                  }
                },
                dropdownColor: Theme.of(context).cardColor,
                items: [
                  DropdownMenuItem(
                    value: ViewDeckType.main,
                    child: Text('Main Deck', style: dropdownItemStyle),
                  ),
                  DropdownMenuItem(
                    value: ViewDeckType.extra,
                    child: Text('Extra Deck', style: dropdownItemStyle),
                  ),
                  DropdownMenuItem(
                    value: ViewDeckType.side,
                    child: Text('Side Deck', style: dropdownItemStyle),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dynamischer Anzeige-Bereich
          SizedBox(height: 400, child: _buildDynamicDeckView()),

          const SizedBox(height: 24),

          // Kommentarsektion (nur wenn deckId vorhanden)
          if (deckId != null) ...[
            CommentSection(deckId: deckId),
            const SizedBox(height: 50),
          ],
        ],
      ),
    );
  }
}

// VERBESSERTE Card Image Widget mit intelligenter Fallback-Logik
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

    // Sammle alle möglichen Bild-URLs in Prioritätsreihenfolge
    final List<String> allImageUrls = [];

    for (var imageEntry in cardImages) {
      if (imageEntry is Map<String, dynamic>) {
        // Priorität 1: image_url (hohe Auflösung)
        final normalUrl = imageEntry['image_url'] as String?;
        if (normalUrl != null && normalUrl.isNotEmpty) {
          allImageUrls.add(normalUrl);
        }

        // Priorität 2: image_url_cropped (zugeschnitten)
        final croppedUrl = imageEntry['image_url_cropped'] as String?;
        if (croppedUrl != null && croppedUrl.isNotEmpty) {
          allImageUrls.add(croppedUrl);
        }

        // Priorität 3: image_url_small (falls vorhanden)
        final smallUrl = imageEntry['image_url_small'] as String?;
        if (smallUrl != null && smallUrl.isNotEmpty) {
          allImageUrls.add(smallUrl);
        }
      }
    }

    // Versuche jede URL nacheinander bis eine funktioniert
    for (var imageUrl in allImageUrls) {
      try {
        final downloadUrl = await widget.cardData.getImgPath(imageUrl);

        if (downloadUrl.isNotEmpty && mounted) {
          setState(() {
            _loadedImageUrl = downloadUrl;
            _isLoading = false;
            _hasError = false;
          });
          return; // Erfolgreich geladen, beende Schleife
        }
      } catch (e) {
        // Fehler beim Laden dieser URL, versuche nächste
        continue;
      }
    }

    // Keine URL hat funktioniert
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
        // Wenn das Netzwerkbild fehlschlägt, zeige Fehler-Icon
        return const SizedBox(
          width: 40,
          height: 60,
          child: Icon(Icons.broken_image, size: 30, color: Colors.red),
        );
      },
    );
  }
}
