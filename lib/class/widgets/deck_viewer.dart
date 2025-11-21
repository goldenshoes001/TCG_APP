// deck_viewer.dart - MIT RIVERPOD
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:tcg_app/providers/app_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

enum ViewDeckType { main, extra, side, notes }

// Provider für selected deck type
final selectedDeckTypeProvider = StateProvider<ViewDeckType>(
  (ref) => ViewDeckType.main,
);

// Provider für selected card in deck viewer
final selectedCardInDeckProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

class DeckViewer extends ConsumerStatefulWidget {
  final Map<String, dynamic> deckData;
  final VoidCallback onBack;

  const DeckViewer({super.key, required this.deckData, required this.onBack});

  @override
  ConsumerState<DeckViewer> createState() => _DeckViewerState();
}

class _DeckViewerState extends ConsumerState<DeckViewer> {
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

  Map<String, List<Map<String, dynamic>>> _sortAndCategorizeCards(
    List<Map<String, dynamic>> cards,
  ) {
    final selectedDeckType = ref.watch(selectedDeckTypeProvider);

    if (selectedDeckType == ViewDeckType.extra) {
      final List<Map<String, dynamic>> sortedCards = List.from(cards)
        ..sort(
          (a, b) => (a['name'] as String? ?? '').compareTo(
            b['name'] as String? ?? '',
          ),
        );
      return {'Monster': sortedCards};
    }

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

  @override
  Widget build(BuildContext context) {
    final selectedCard = ref.watch(selectedCardInDeckProvider);

    if (selectedCard != null) {
      return CardDetailView(
        cardData: selectedCard,
        onBack: () {
          ref.read(selectedCardInDeckProvider.notifier).state = null;
        },
      );
    }

    return Column(
      children: [
        _buildCustomAppBar(context),
        _buildDeckTypeTabs(),
        Expanded(child: _buildCurrentView()),
      ],
    );
  }

  Widget _buildCurrentView() {
    final selectedDeckType = ref.watch(selectedDeckTypeProvider);

    switch (selectedDeckType) {
      case ViewDeckType.main:
      case ViewDeckType.extra:
      case ViewDeckType.side:
        return _buildCardList();
      case ViewDeckType.notes:
        return _buildDeckNotes();
    }
  }

  Widget _buildDeckNotes() {
    final deckId =
        (widget.deckData['id'] ?? widget.deckData['deckId']) as String?;

    if (deckId == null || deckId.isEmpty) {
      return const Center(
        child: Text('Fehler: Deck ID nicht gefunden, um Kommentare zu laden.'),
      );
    }

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
    final selectedDeckType = ref.watch(selectedDeckTypeProvider);

    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ViewDeckType.values.map((type) {
          bool isSelected = selectedDeckType == type;
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
            case ViewDeckType.notes:
              label = 'Comments';
              break;
          }

          return TextButton(
            onPressed: () {
              ref.read(selectedDeckTypeProvider.notifier).state = type;
            },
            child: Text(label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardList() {
    final selectedDeckType = ref.watch(selectedDeckTypeProvider);
    final cardData = ref.watch(cardDataProvider);

    List<Map<String, dynamic>> currentDeck;
    String deckName;

    switch (selectedDeckType) {
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

    final totalCardCount = currentDeck.fold<int>(0, (sum, card) {
      return sum + (card['count'] as int? ?? 1);
    });

    if (currentDeck.isEmpty) {
      return Center(child: Text('$deckName ist leer.'));
    }

    final categorizedCards = _sortAndCategorizeCards(currentDeck);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text('$deckName ($totalCardCount Cards)'),
          ),
          const Divider(),

          ...categorizedCards.entries.map((entry) {
            final category = entry.key;
            final cards = entry.value;

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
                      leading: _CardImageWidget(card: card, cardData: cardData),
                      title: Text(card['name'] ?? 'Unbekannte Karte'),
                      subtitle: Text(card['type'] ?? ''),
                      trailing: Text('x$count'),
                      onTap: () {
                        ref.read(selectedCardInDeckProvider.notifier).state =
                            card;
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
}

// ====================================================================
// COMMENT SECTION MIT RIVERPOD
// ====================================================================
class CommentSection extends ConsumerStatefulWidget {
  final String deckId;
  const CommentSection({super.key, required this.deckId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      final deckService = ref.read(deckServiceProvider);
      await deckService.addComment(deckId: widget.deckId, comment: comment);
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
      final deckService = ref.read(deckServiceProvider);
      await deckService.deleteComment(
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
    final currentUser = ref.watch(currentUserProvider);
    final deckService = ref.watch(deckServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comments'),
          const SizedBox(height: 16),
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
          StreamBuilder<QuerySnapshot>(
            stream: deckService.getComments(widget.deckId),
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
                    child: Text('No Comments'),
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

                  final canDelete = currentUser?.uid == userId;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(commentText),
                          const SizedBox(height: 4),
                          if (timestamp != null)
                            Text(
                              DateFormat(
                                'dd.MM.yyyy HH:mm',
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

// Card Image Widget (unverändert, aber mit ref)
class _CardImageWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> card;
  final CardData cardData;

  const _CardImageWidget({required this.card, required this.cardData});

  @override
  ConsumerState<_CardImageWidget> createState() => _CardImageWidgetState();
}

class _CardImageWidgetState extends ConsumerState<_CardImageWidget> {
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
