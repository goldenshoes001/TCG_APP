// deck_viewer.dart - Final mit dynamischen Deck-Kommentaren und CardDetailView
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // NEU: Für Datumsformatierung in CommentSection

// NEUE ENUM: 'notes' hinzugefügt
enum ViewDeckType { main, extra, side, notes }

class DeckViewer extends StatefulWidget {
  final Map<String, dynamic> deckData;
  final VoidCallback onBack;

  const DeckViewer({super.key, required this.deckData, required this.onBack});

  @override
  State<DeckViewer> createState() => _DeckViewerState();
}

class _DeckViewerState extends State<DeckViewer> {
  final CardData _cardData = CardData();
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

  // --- HILFSFUNKTION FÜR KATEGORISIERUNG UND SORTIERUNG ---
  Map<String, List<Map<String, dynamic>>> _sortAndCategorizeCards(
    List<Map<String, dynamic>> cards,
  ) {
    // ✅ FÜR EXTRA DECK: NUR MONSTER ANZEIGEN (OHNE UNTERKATEGORIEN)
    if (_selectedDeckType == ViewDeckType.extra) {
      // Einfach alle Karten als "Monster" zurückgeben
      final List<Map<String, dynamic>> sortedCards = List.from(cards)
        ..sort(
          (a, b) => (a['name'] as String? ?? '').compareTo(
            b['name'] as String? ?? '',
          ),
        );

      return {'Monster': sortedCards};
    }

    // ✅ FÜR MAIN DECK: NORMALE KATEGORISIERUNG BEIBEHALTEN
    final Map<String, List<Map<String, dynamic>>> categorized = {
      'Monster': [],
      'Zauber': [],
      'Falle': [],
      'Andere': [],
    };

    for (var card in cards) {
      final frameType = (card['frameType'] as String? ?? '').toLowerCase();
      final type = (card['type'] as String? ?? '').toLowerCase();

      if (frameType.contains('monster') ||
          frameType.contains('xyz') ||
          frameType.contains('synchro') ||
          frameType.contains('fusion') ||
          frameType.contains('link') ||
          frameType.contains('pendulum') ||
          type.contains('monster')) {
        categorized['Monster']!.add(card);
      } else if (frameType.contains('spell') || type.contains('spell')) {
        categorized['Zauber']!.add(card);
      } else if (frameType.contains('trap') || type.contains('trap')) {
        categorized['Falle']!.add(card);
      } else {
        categorized['Andere']!.add(card);
      }
    }

    // Alphabetisch sortieren innerhalb jeder Kategorie
    categorized.forEach((key, list) {
      list.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
    });

    if (categorized['Andere']!.isEmpty) {
      categorized.remove('Andere');
    }

    return categorized;
  }
  // --- ENDE HILFSFUNKTION ---

  @override
  Widget build(BuildContext context) {
    // Wenn eine Karte ausgewählt wurde, zeige NUR CardDetailView (OHNE AppBar/Tabs)
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

    // Ansonsten zeige die normale Deckliste mit AppBar und Tabs
    return Column(
      children: [
        _buildCustomAppBar(context),
        _buildDeckTypeTabs(),
        Expanded(child: _buildCurrentView()),
      ],
    );
  }

  // Wählt die anzuzeigende Ansicht basierend auf _selectedDeckType
  Widget _buildCurrentView() {
    switch (_selectedDeckType) {
      case ViewDeckType.main:
      case ViewDeckType.extra:
      case ViewDeckType.side:
        return _buildCardList();
      case ViewDeckType.notes:
        return _buildDeckNotes(); // Hier wird der CommentSection aufgerufen
    }
  }

  // NEU: Aufruf des CommentSection Widgets
  Widget _buildDeckNotes() {
    // Annahme: Die Deck ID ist im Map unter 'id' oder 'deckId' gespeichert.
    final deckId =
        (widget.deckData['id'] ?? widget.deckData['deckId']) as String?;

    if (deckId == null || deckId.isEmpty) {
      return const Center(
        child: Text('Fehler: Deck ID nicht gefunden, um Kommentare zu laden.'),
      );
    }

    // Verwende das bereitgestellte CommentSection Widget
    return CommentSection(deckId: deckId);
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    const double toolbarHeight = kToolbarHeight;

    return Container(
      height: topPadding + toolbarHeight,
      padding: EdgeInsets.only(top: topPadding),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  widget.deckData['name'] ?? "",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckTypeTabs() {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ViewDeckType.values.map((type) {
          bool isSelected = _selectedDeckType == type;
          String label;
          switch (type) {
            case ViewDeckType.main:
              label = 'MAIN';
              break;
            case ViewDeckType.extra:
              label = 'EXTRA';
              break;
            case ViewDeckType.side:
              label = 'SIDE';
              break;
            case ViewDeckType.notes: // REITER 'NOTES'
              label = 'Comments';
              break;
          }

          return TextButton(
            onPressed: () {
              setState(() {
                _selectedDeckType = type;
              });
            },
            child: Text(label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardList() {
    List<Map<String, dynamic>> currentDeck;
    String deckName;

    switch (_selectedDeckType) {
      case ViewDeckType.main:
        currentDeck = _mainDeck;
        deckName = 'Main Deck';
        break;
      case ViewDeckType.extra:
        currentDeck = _extraDeck;
        deckName = 'Extra Deck';
        break;
      case ViewDeckType.side:
        currentDeck = _sideDeck;
        deckName = 'Side Deck';
        break;
      default:
        currentDeck = [];
        deckName = 'Unbekannt';
    }

    // ✅ GESAMTANZAHL DER KARTEN BERECHNEN (MIT COUNT)
    final totalCardCount = currentDeck.fold<int>(0, (sum, card) {
      return sum +
          (card['count'] as int? ?? 1); // count oder 1 falls nicht vorhanden
    });

    // ✅ ANZAHL UNTERSCHIEDLICHER KARTEN
    final uniqueCardCount = currentDeck.length;

    if (currentDeck.isEmpty) {
      return Center(child: Text('$deckName ist leer.'));
    }

    final categorizedCards = _sortAndCategorizeCards(currentDeck);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ GESAMTANZAHL ANZEIGEN
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text('$deckName ($totalCardCount Cards)'),
          ),
          const Divider(),

          ...categorizedCards.entries.map((entry) {
            final category = entry.key;
            final cards = entry.value;

            // ✅ ANZAHL IN DER KATEGORIE BERECHNEN (MIT COUNT)
            final categoryCardCount = cards.fold<int>(0, (sum, card) {
              return sum + (card['count'] as int? ?? 1);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('$category ($categoryCardCount)'),
                ),
                Column(
                  children: cards.map((card) {
                    final count = card['count'] ?? 1;
                    return ListTile(
                      leading: _CardImageWidget(
                        card: card,
                        cardData: _cardData,
                      ),
                      title: Text(card['name'] ?? 'Unbekannte Karte'),
                      subtitle: Text(card['type'] ?? ''),
                      trailing: Text('x$count'),
                      onTap: () {
                        setState(() {
                          _selectedCardForDetail = card;
                        });
                      },
                    );
                  }).toList(),
                ),
                const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  // _buildCardDetail verwendet CardDetailView und setzt den State zurück
  Widget _buildCardDetail() {
    return CardDetailView(
      cardData: _selectedCardForDetail!,
      onBack: () {
        setState(() {
          _selectedCardForDetail = null; // Zurück zur Deckliste
        });
      },
    );
  }
}

// ====================================================================
// VOM BENUTZER BEREITGESTELLTES WIDGET FÜR DIE KOMMENTARE
// ====================================================================
class CommentSection extends StatefulWidget {
  final String deckId;
  const CommentSection({super.key, required this.deckId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  // DeckService muss hier lokal initialisiert werden, da es eine separate Klasse ist
  final DeckService _deckService = DeckService();
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      await _deckService.addComment(deckId: widget.deckId, comment: comment);
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kommentar hinzugefügt')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _deckService.deleteComment(
        deckId: widget.deckId,
        commentId: commentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kommentar gelöscht')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return SingleChildScrollView(
      // Füge SingleChildScrollView hinzu, falls die Kommentare den Bildschirm übersteigen
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comments'),
          const SizedBox(height: 16),

          // Kommentar hinzufügen
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "Write a Comment",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send), onPressed: _addComment),
            ],
          ),

          const SizedBox(height: 16),

          // Kommentare anzeigen
          StreamBuilder<QuerySnapshot>(
            stream: _deckService.getComments(widget.deckId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Fehler: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No Comments"),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment =
                      comments[index].data() as Map<String, dynamic>;
                  final commentId = comment['commentId'] as String;
                  final userId = comment['userId'] as String;
                  final username = comment['username'] as String;
                  final commentText = comment['comment'] as String;
                  final timestamp = comment['createdAt'] as Timestamp?;

                  final canDelete = currentUserId == userId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(commentText),
                          if (timestamp != null)
                            Text(
                              DateFormat(
                                'dd.MM.yyyy',
                              ).format(timestamp.toDate().toLocal()),
                            ),
                        ],
                      ),
                      trailing: canDelete
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteComment(commentId),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Card Image Widget (unberührt gelassen)
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
