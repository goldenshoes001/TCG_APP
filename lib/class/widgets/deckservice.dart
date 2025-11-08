// deckservice.dart - MIT COVER-BILD FUNKTIONALITÄT
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    String? coverImageUrl,
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
      'coverImageUrl': coverImageUrl,
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
    String? coverImageUrl,
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
      'coverImageUrl': coverImageUrl,
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
    // Entferne überflüssige Leerzeichen und trimme
    final combined = '$deckName $archetype $description'
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return combined;
  }

  Future<void> deleteDeck(String deckId) async {
    final commentsRef = _firestore
        .collection('decks')
        .doc(deckId)
        .collection('comments');

    final snapshot = await commentsRef.get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _firestore.collection('decks').doc(deckId).delete();
  }

  List<String> _generateSearchTokens(
    String deckName,
    String archetype,
    String description,
  ) {
    final searchIndex = _generateSearchIndex(deckName, archetype, description);

    final tokens = searchIndex
        .split(RegExp(r'[\s,]+'))
        .where((token) => token.trim().isNotEmpty)
        .map((token) => token.trim().toLowerCase())
        .toSet()
        .toList();

    return tokens;
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

    String username = 'Unbekannter Benutzer';
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        username =
            userData?['username'] ??
            userData?['displayName'] ??
            user.displayName ??
            user.email ??
            'Unbekannter Benutzer';
      } else {
        username =
            user.displayName ??
            user.email?.split('@')[0] ??
            'Unbekannter Benutzer';
      }
    } catch (e) {
      print('Fehler beim Laden des Benutzernamens: $e');
      username =
          user.displayName ??
          user.email?.split('@')[0] ??
          'Unbekannter Benutzer';
    }

    await _firestore
        .collection('decks')
        .doc(deckId)
        .collection('comments')
        .doc(commentId)
        .set({
          'commentId': commentId,
          'userId': user.uid,
          'username': username,
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
// 2. DeckCreationScreen: Formular-Inhalt MIT COVER-BILD
// ============================================================================

enum DeckType { main, extra, side, comments }

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
  String? _coverImageUrl;
  Map<String, dynamic>? _selectedCardForDetail;
  DeckType _selectedDeckType = DeckType.main;

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
      _coverImageUrl = deck['coverImageUrl'] as String?;

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
        'coverImageUrl': _coverImageUrl,
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

  void _showCoverImageSelector() {
    final allCards = [..._mainDeck, ..._extraDeck];

    if (allCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Füge zuerst Karten zum Deck hinzu')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deck Cover-Bild auswählen'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: allCards.length,
              itemBuilder: (context, index) {
                final card = allCards[index];
                final cardImages = card['card_images'] as List<dynamic>?;

                // Sammle alle verfügbaren Bild-URLs aus ALLEN Array-Einträgen
                List<String> availableUrls = [];

                if (cardImages != null && cardImages.isNotEmpty) {
                  // Durchlaufe ALLE Einträge im card_images Array (für Dark Magician Girl etc.)
                  for (var imageEntry in cardImages) {
                    if (imageEntry is Map<String, dynamic>) {
                      // Priorität: image_url > image_url_small > image_url_cropped
                      final imageUrl = imageEntry['image_url'] as String?;
                      final smallUrl = imageEntry['image_url_small'] as String?;
                      final croppedUrl =
                          imageEntry['image_url_cropped'] as String?;

                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        availableUrls.add(imageUrl);
                      }
                      if (smallUrl != null && smallUrl.isNotEmpty) {
                        availableUrls.add(smallUrl);
                      }
                      if (croppedUrl != null && croppedUrl.isNotEmpty) {
                        availableUrls.add(croppedUrl);
                      }
                    }
                  }
                }

                return InkWell(
                  onTap: () async {
                    if (availableUrls.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kein Bild für ${card['name']} verfügbar',
                          ),
                        ),
                      );
                      return;
                    }

                    // Finde die erste funktionierende URL
                    String? workingUrl;
                    for (String url in availableUrls) {
                      try {
                        final downloadUrl = await _cardData.getImgPath(url);
                        if (downloadUrl.isNotEmpty) {
                          workingUrl = url;
                          break; // Erste funktionierende gefunden!
                        }
                      } catch (e) {
                        continue; // Probiere die nächste
                      }
                    }

                    if (workingUrl != null) {
                      setState(() {
                        _coverImageUrl = workingUrl;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cover-Bild auf "${card['name']}" gesetzt',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Keine funktionierende Bild-URL für ${card['name']} gefunden',
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: _CardImageWidget(
                            card: card,
                            cardData: _cardData,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            card['name'] as String? ?? '',
                            style: const TextStyle(fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  void _addCardToDeck(Map<String, dynamic> card, int count) {
    final frameType = (card['frameType'] as String? ?? '').toLowerCase();
    List<Map<String, dynamic>> targetDeck;

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

    final cardId = card['id']?.toString() ?? card['name'];
    final existingIndex = targetDeck.indexWhere(
      (c) => (c['id']?.toString() ?? c['name']) == cardId,
    );

    final banlistInfo = card['banlist_info'];
    int maxAllowed = 3;
    if (banlistInfo != null) {
      final tcgBan = banlistInfo['ban_tcg'] as String?;
      if (tcgBan == 'Forbidden') {
        maxAllowed = 0;
      } else if (tcgBan == 'Limited')
        maxAllowed = 1;
      else if (tcgBan == 'Semi-Limited')
        maxAllowed = 2;
    }

    if (existingIndex != -1) {
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
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeCardFromDeck(card, deck),
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

  Widget _buildDeckTypeTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: DeckType.values.map((type) {
          if (type == DeckType.comments && _currentDeckId == null) {
            return const SizedBox.shrink();
          }

          bool isSelected = _selectedDeckType == type;
          String label;
          switch (type) {
            case DeckType.main:
              label = 'MAIN';
              break;
            case DeckType.extra:
              label = 'EXTRA';
              break;
            case DeckType.side:
              label = 'SIDE';
              break;
            case DeckType.comments:
              label = 'KOMMENTARE';
              break;
          }

          return TextButton(
            onPressed: () {
              setState(() {
                _selectedDeckType = type;
              });
            },
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicDeckView() {
    DeckType currentType = _selectedDeckType;
    String title;
    List<Map<String, dynamic>> deck = [];

    switch (currentType) {
      case DeckType.main:
        title = 'Main Deck';
        deck = _mainDeck;
        break;
      case DeckType.extra:
        title = 'Extra Deck';
        deck = _extraDeck;
        break;
      case DeckType.side:
        title = 'Side Deck';
        deck = _sideDeck;
        break;
      case DeckType.comments:
        title = 'Kommentare';
        if (_currentDeckId == null) {
          return const Center(
            child: Text(
              'Deck muss zuerst gespeichert werden, um Kommentare anzuzeigen.',
            ),
          );
        }
        return CommentSection(deckId: _currentDeckId!);
    }

    final totalCards = deck.fold(
      0,
      (sum, card) => sum + (card['count'] as int? ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, top: 8.0),
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
    // Wenn Detail-Ansicht, zeige NUR die Karte (OHNE obere Buttons)
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

    // Ansonsten zeige die normale Editing-Ansicht
    if (_isLoading || _isSaving) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover-Bild Anzeige
                if (_coverImageUrl != null)
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FutureBuilder<String>(
                            future: _cardData.getCorrectImgPath([
                              _coverImageUrl!,
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: const EdgeInsets.all(4),
                            ),
                            onPressed: () {
                              setState(() {
                                _coverImageUrl = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_coverImageUrl != null) const SizedBox(height: 16),

                // Cover-Bild Button
                OutlinedButton.icon(
                  onPressed: _showCoverImageSelector,
                  icon: const Icon(Icons.image),
                  label: Text(
                    _coverImageUrl == null
                        ? 'Deck Cover-Bild auswählen'
                        : 'Cover-Bild ändern',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _deckNameController,
                  decoration: const InputDecoration(
                    labelText: 'Deck Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        ),

        _buildDeckTypeTabs(),

        Expanded(child: _buildDynamicDeckView()),
      ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kommentare', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Kommentar schreiben...',
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
                  final comment =
                      comments[index].data() as Map<String, dynamic>;
                  final commentId = comment['commentId'] as String;
                  final userId = comment['userId'] as String;
                  final username = comment['username'] as String;
                  final commentText = comment['comment'] as String;
                  final timestamp = comment['createdAt'] as Timestamp?;

                  final canDelete = currentUserId == userId;

                  return Container(
                    color: Theme.of(context).cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        username,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            commentText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          if (timestamp != null)
                            Text(
                              DateFormat(
                                'dd.MM.yyyy HH:mm',
                              ).format(timestamp.toDate().toLocal()),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
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

// ============================================================================
// Card Image Widget
// ============================================================================

class _CardImageWidget extends StatefulWidget {
  final Map<String, dynamic> card;
  final CardData cardData;
  final BoxFit fit;

  const _CardImageWidget({
    required this.card,
    required this.cardData,
    this.fit = BoxFit.cover,
  });

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
      fit: widget.fit,
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
