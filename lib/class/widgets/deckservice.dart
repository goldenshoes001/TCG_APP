// deckservice.dart - VOLLSTÄNDIG ÜBERARBEITET MIT KOMMENTARFUNKTION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'card_search_dialog.dart';

// ============================================================================
// 1. DeckService - Firestore Service für Deck-Operationen
// ============================================================================

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<Map<String, dynamic>> readDeck(String deckId) async {
    final docSnapshot = await _firestore.collection('decks').doc(deckId).get();

    if (!docSnapshot.exists) {
      throw Exception('Deck mit ID $deckId nicht gefunden.');
    }

    return docSnapshot.data()!;
  }

  List<String> _extractArchetypes(
    List<Map<String, dynamic>> mainDeck,
    List<Map<String, dynamic>> extraDeck,
  ) {
    final Set<String> archetypes = {};

    for (var card in [...mainDeck, ...extraDeck]) {
      final archetype = card['archetype'] as String?;
      if (archetype != null && archetype.isNotEmpty) {
        archetypes.add(archetype);
      }
    }

    return archetypes.toList()..sort();
  }

  Future<void> updateDeck({
    required String deckId,
    required String deckName,
    required String description,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final archetypes = _extractArchetypes(mainDeck, extraDeck);
    final archetypeString = archetypes.join(', ');

    final searchIndex = _generateSearchIndex(
      deckName,
      archetypeString,
      description,
    );
    final searchTokens = _generateSearchTokens(
      deckName,
      archetypeString,
      description,
    );

    await _firestore.collection('decks').doc(deckId).update({
      'deckName': deckName,
      'archetype': archetypeString,
      'description': description,
      'mainDeck': mainDeck,
      'extraDeck': extraDeck,
      'sideDeck': sideDeck,
      'searchIndex': searchIndex,
      'searchTokens': searchTokens,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isDeckNameDuplicate({
    required String deckName,
    required String deckNameLower,
    String? excludeDeckId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final decksRef = _firestore.collection('decks');
    deckName = deckName.trim().toLowerCase();

    QuerySnapshot snapshot = await decksRef
        .where('deckName', isEqualTo: deckName)
        .where('littleName', isEqualTo: deckNameLower)
        .get();

    for (var doc in snapshot.docs) {
      final deckData = doc.data() as Map<String, dynamic>;
      final foundDeckId = deckData['deckId'] as String;

      if (excludeDeckId == null || foundDeckId != excludeDeckId) {
        return true;
      }
    }

    return false;
  }

  Future<String> createDeck({
    required String deckName,
    required String description,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    final user = _auth.currentUser;
    final deckNameLower = deckName.trim().toLowerCase();

    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final isDuplicate = await isDeckNameDuplicate(
      deckName: deckName,
      deckNameLower: deckNameLower,
    );

    if (isDuplicate) {
      throw Exception(
        'Ein Deck mit dem Namen "$deckName" existiert bereits. Bitte wähle einen anderen Namen.',
      );
    }

    final deckId = _uuid.v4();
    final archetypes = _extractArchetypes(mainDeck, extraDeck);
    final archetypeString = archetypes.join(', ');

    final searchIndex = _generateSearchIndex(
      deckName,
      archetypeString,
      description,
    );
    final searchTokens = _generateSearchTokens(
      deckName,
      archetypeString,
      description,
    );

    await _firestore.collection('decks').doc(deckId).set({
      'deckId': deckId,
      'userId': user.uid,
      'username': user.displayName ?? user.email,
      'littleName': deckNameLower,
      'deckName': deckName,
      'archetype': archetypeString,
      'description': description,
      'mainDeck': mainDeck,
      'extraDeck': extraDeck,
      'sideDeck': sideDeck,
      'searchIndex': searchIndex,
      'searchTokens': searchTokens,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return deckId;
  }

  String _generateSearchIndex(
    String deckName,
    String archetype,
    String description,
  ) {
    return '$deckName $archetype $description'.toLowerCase();
  }

  Future<void> deleteDeck(String deckId) async {
    await _firestore.collection('decks').doc(deckId).delete();
  }

  List<String> _generateSearchTokens(
    String deckName,
    String archetype,
    String description,
  ) {
    return _generateSearchIndex(deckName, archetype, description).split(' ');
  }

  // Kommentar-Funktionen
  Future<void> addComment({
    required String deckId,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final commentId = _uuid.v4();

    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('comments')
        .doc(commentId)
        .set({
          'commentId': commentId,
          'userId': user.uid,
          'username': user.displayName ?? user.email ?? 'Unbekannt',
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> getComments(String deckId) {
    return _firestore
        .collection('decks')
        .doc(deckId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteComment({
    required String deckId,
    required String commentId,
  }) async {
    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}

// ============================================================================
// 2. DeckCreationScreen: Formular-Inhalt
// ============================================================================

class DeckCreationScreen extends StatefulWidget {
  final String? initialDeckId;
  final void Function(Map<String, dynamic> data) onDataCollected;

  const DeckCreationScreen({
    super.key,
    this.initialDeckId,
    required this.onDataCollected,
  });

  @override
  State<DeckCreationScreen> createState() => DeckCreationScreenState();
}

class DeckCreationScreenState extends State<DeckCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deckNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _mainDeck = [];
  List<Map<String, dynamic>> _extraDeck = [];
  List<Map<String, dynamic>> _sideDeck = [];

  final DeckService _deckService = DeckService();
  final CardData _cardData = CardData();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _addToSideDeck = false;
  String? _currentDeckId;
  Map<String, dynamic>? _selectedCardForDetail;

  @override
  void initState() {
    super.initState();
    _currentDeckId = widget.initialDeckId;
    _loadDeckData();
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDeckData() async {
    if (_currentDeckId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final deck = await _deckService.readDeck(_currentDeckId!);

      _deckNameController.text = deck['deckName'] as String;
      _descriptionController.text = deck['description'] as String? ?? '';

      _mainDeck =
          (deck['mainDeck'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [];
      _extraDeck =
          (deck['extraDeck'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [];
      _sideDeck =
          (deck['sideDeck'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [];

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Decks: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? collectDeckDataAndValidate() {
    if (_formKey.currentState!.validate() &&
        _deckNameController.text.trim().isNotEmpty) {
      return {
        'deckName': _deckNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mainDeck': _mainDeck,
        'extraDeck': _extraDeck,
        'sideDeck': _sideDeck,
      };
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Das Deck muss einen Namen haben.')),
      );
    }
    return null;
  }

  void setSaving(bool saving) {
    if (mounted) {
      setState(() => _isSaving = saving);
    }
  }

  void _showCardSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CardSearchDialog(
          isSideDeck: _addToSideDeck,
          onCardSelected: (card, count) {
            _addCardToDeck(card, count);
          },
        );
      },
    );
  }

  void _addCardToDeck(Map<String, dynamic> card, int count) {
    final frameType = (card['frameType'] as String? ?? '').toLowerCase();
    List<Map<String, dynamic>> targetDeck;

    // Bestimme Ziel-Deck
    if (_addToSideDeck) {
      targetDeck = _sideDeck;
    } else if (frameType == 'fusion' ||
        frameType == 'synchro' ||
        frameType == 'xyz' ||
        frameType == 'link' ||
        frameType == 'fusion_pendulum' ||
        frameType == 'synchro_pendulum' ||
        frameType == 'xyz_pendulum') {
      targetDeck = _extraDeck;
    } else {
      targetDeck = _mainDeck;
    }

    // Prüfen ob Karte bereits existiert
    final cardId = card['id']?.toString() ?? card['name'];
    final existingIndex = targetDeck.indexWhere(
      (c) => (c['id']?.toString() ?? c['name']) == cardId,
    );

    // Bannlisten-Check: Maximale erlaubte Anzahl
    final banlistInfo = card['banlist_info'];
    int maxAllowed = 3;
    if (banlistInfo != null) {
      final tcgBan = banlistInfo['ban_tcg'] as String?;
      if (tcgBan == 'Forbidden')
        maxAllowed = 0;
      else if (tcgBan == 'Limited')
        maxAllowed = 1;
      else if (tcgBan == 'Semi-Limited')
        maxAllowed = 2;
    }

    if (existingIndex != -1) {
      // Karte existiert bereits - prüfe Limit
      final existingCount = targetDeck[existingIndex]['count'] as int? ?? 0;
      final newTotal = existingCount + count;

      if (newTotal > maxAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limit überschritten! ${card['name']} ist auf $maxAllowed Kopien limitiert.',
            ),
          ),
        );
        return;
      }

      targetDeck[existingIndex] = {
        ...targetDeck[existingIndex],
        'count': newTotal,
      };
    } else {
      // Neue Karte hinzufügen - prüfe Limit
      if (count > maxAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Limit überschritten! ${card['name']} ist auf $maxAllowed Kopien limitiert.',
            ),
          ),
        );
        return;
      }

      final cardToAdd = Map<String, dynamic>.from(card);
      cardToAdd['count'] = count;
      targetDeck.add(cardToAdd);
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card['name']} ${count}x hinzugefügt')),
    );
  }

  void _removeCardFromDeck(
    Map<String, dynamic> card,
    List<Map<String, dynamic>> deck,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentCount = card['count'] as int? ?? 0;

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Karte entfernen'),
          content: Text('Wie viele Kopien von "${card['name']}" entfernen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ...List.generate(currentCount, (index) {
              final removeCount = index + 1;
              return TextButton(
                onPressed: () {
                  setState(() {
                    final cardId = card['id']?.toString() ?? card['name'];
                    final cardIndex = deck.indexWhere(
                      (c) => (c['id']?.toString() ?? c['name']) == cardId,
                    );

                    if (cardIndex != -1) {
                      if (removeCount >= currentCount) {
                        deck.removeAt(cardIndex);
                      } else {
                        deck[cardIndex] = {
                          ...deck[cardIndex],
                          'count': currentCount - removeCount,
                        };
                      }
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: Text('$removeCount${removeCount == 1 ? 'x' : 'x'}'),
              );
            }),
          ],
        );
      },
    );
  }

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
      return Expanded(
        child: Center(
          child: Text(
            'Keine Karten im $title',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Kategorisierung
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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...cards.map((card) {
            final cardImages = card['card_images'] as List<dynamic>?;
            final imageUrl = cardImages != null && cardImages.isNotEmpty
                ? (cardImages[0]
                          as Map<String, dynamic>)['image_url_cropped'] ??
                      ''
                : '';

            final count = card['count'] as int? ?? 0;
            final name = card['name'] as String? ?? 'Unbekannt';

            return Card(
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

                      if (imageUrl.isNotEmpty)
                        FutureBuilder<String>(
                          future: _cardData.getImgPath(imageUrl),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return Image.network(
                                snapshot.data!,
                                width: 40,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  );
                                },
                              );
                            }
                            return const SizedBox(
                              width: 40,
                              height: 60,
                              child: Icon(Icons.image),
                            );
                          },
                        )
                      else
                        const SizedBox(
                          width: 40,
                          height: 60,
                          child: Icon(Icons.image),
                        ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeCardFromDeck(card, deck),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      );
    }

    final totalCards = getTotalCount(deck);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$title ($totalCards Karten)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildCategory('Monster', categorized['Monster']!),
                  buildCategory('Spell', categorized['Spell']!),
                  buildCategory('Trap', categorized['Trap']!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDeck() {
    if (_sideDeck.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Keine Karten im Side Deck'),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sideDeck.length,
        itemBuilder: (context, index) {
          final card = _sideDeck[index];
          final cardImages = card['card_images'] as List<dynamic>?;
          final imageUrl = cardImages != null && cardImages.isNotEmpty
              ? (cardImages[0] as Map<String, dynamic>)['image_url_cropped'] ??
                    ''
              : '';

          final count = card['count'] as int? ?? 0;
          final name = card['name'] as String? ?? 'Unbekannt';

          return Card(
            margin: const EdgeInsets.all(4),
            child: InkWell(
              onTap: () => _showCardDetail(card),
              child: Container(
                width: 80,
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    if (imageUrl.isNotEmpty)
                      FutureBuilder<String>(
                        future: _cardData.getImgPath(imageUrl),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Image.network(
                              snapshot.data!,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Icon(Icons.image, size: 60);
                        },
                      )
                    else
                      const Icon(Icons.image, size: 60),

                    Text('${count}x', style: const TextStyle(fontSize: 10)),

                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeCardFromDeck(card, _sideDeck),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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

    if (_isLoading || _isSaving) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Deck Name Feld
            TextField(
              controller: _deckNameController,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Karte hinzufügen Button mit Side Deck Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCardSearchDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Karte hinzufügen'),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _addToSideDeck,
                      onChanged: (value) {
                        setState(() {
                          _addToSideDeck = value ?? false;
                        });
                      },
                    ),
                    const Text('Zum Side Deck'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main Deck und Extra Deck nebeneinander
            SizedBox(
              height: 400,
              child: Row(
                children: [
                  _buildDeckSection(title: 'Main Deck', deck: _mainDeck),
                  const SizedBox(width: 8),
                  _buildDeckSection(title: 'Extra Deck', deck: _extraDeck),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Side Deck
            Text(
              'Side Deck (${_sideDeck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0))} Karten)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSideDeck(),

            const SizedBox(height: 24),

            if (_currentDeckId != null) ...[
              CommentSection(deckId: _currentDeckId!),
              const SizedBox(height: 50),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CommentSection
// ============================================================================

class CommentSection extends StatefulWidget {
  final String deckId;
  const CommentSection({super.key, required this.deckId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kommentare', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        // Kommentar hinzufügen
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Kommentar schreiben...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                  child: Text('Noch keine Kommentare'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index].data() as Map<String, dynamic>;
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
                            timestamp.toDate().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
