import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tcg_app/class/widgets/ydkexportService.dart';

import 'package:uuid/uuid.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';
import 'card_search_dialog.dart';

// ============================================================================
// DeckService
// ============================================================================

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  Future<Map<String, dynamic>> readDeck(String deckId) async {
    final docSnapshot = await _firestore.collection('decks').doc(deckId).get();

    if (!docSnapshot.exists) {
      throw Exception('Deck with ID $deckId not found .');
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
      throw Exception("User isn't logged in");
    }
    String? username = await _getUsernameFromFirestore(user.uid);
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
      "username": username,
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
      throw Exception("User isn't logged in ");
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
      throw Exception("User isn't logged in");
    }
    String? username = await _getUsernameFromFirestore(user.uid);
    final isDuplicate = await isDeckNameDuplicate(
      deckName: deckName,
      deckNameLower: deckNameLower,
    );

    if (isDuplicate) {
      throw Exception(
        'A deck with the name "$deckName" already exists. Pls choose a other name',
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
      'username': username,
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
    final combined = '$deckName $archetype $description'
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return combined;
  }

  Future<void> deleteDeck(String deckId) async {
    // Lösche alle Kommentare
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

    // Lösche das Deck
    await _firestore.collection('decks').doc(deckId).delete();

    print('✅ Deck $deckId has been deleted!');
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

  Future<void> addComment({
    required String deckId,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User isn't logged in");
    }

    final commentId = _uuid.v4();

    String username = 'Unknown user';
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        username =
            userData?['username'] ??
            userData?['displayName'] ??
            user.displayName ??
            user.email ??
            'Unknown User';
      } else {
        username =
            user.displayName ?? user.email?.split('@')[0] ?? 'Unknown Userr';
      }
    } catch (e) {
      print('Error on loading username: $e');
      username =
          user.displayName ?? user.email?.split('@')[0] ?? 'Unknown user';
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

  Future<String?> _getUsernameFromFirestore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['username'] as String?;
      }
      return null;
    } catch (e) {
      print('Error on loading username: $e');
      return null;
    }
  }
}

// ============================================================================
// DeckCreationScreen: OPTIMIERTES LAYOUT
// ============================================================================

enum DeckType { main, extra, side, comments }

class DeckCreationScreen extends StatefulWidget {
  final String? initialDeckId;
  final void Function(Map<String, dynamic> data) onDataCollected;
  final void Function(bool isShowingDetail)? onDetailViewChanged;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

  const DeckCreationScreen({
    super.key,
    this.initialDeckId,
    required this.onDataCollected,
    this.onDetailViewChanged,
    this.onCancel,
    this.onSaved,
  });

  @override
  State<DeckCreationScreen> createState() => DeckCreationScreenState();
}

class DeckCreationScreenState extends State<DeckCreationScreen> {
  bool get isShowingCardDetail => _selectedCardForDetail != null;

  // Hinzugefügter Getter, um zu prüfen, ob alle Decks leer sind
  bool get isDeckEmpty =>
      _mainDeck.isEmpty && _extraDeck.isEmpty && _sideDeck.isEmpty;

  final _deckNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _mainDeck = [];
  List<Map<String, dynamic>> _extraDeck = [];
  List<Map<String, dynamic>> _sideDeck = [];

  final DeckService _deckService = DeckService();
  final CardData _cardData = CardData();
  final YdkImportService _ydkImportService = YdkImportService();

  bool _isLoading = true;
  bool _isSaving = false;
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


  /// ✅ NEU: Multi-YDK Import Handler
  Future<void> _handleMultiYdkImport() async {
    try {
      final results = await _ydkImportService.importMultipleYdkFiles();

      if (results == null || results.isEmpty) {
        return; // User hat abgebrochen
      }

      // Zeige Bestätigungsdialog
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('${results.length} Deck(s) importieren?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Es wurden ${results.length} YDK-Datei(en) gefunden:'),
                  const SizedBox(height: 12),
                  ...results.take(5).map((deck) {
                    final mainCount = deck.mainDeck.fold(
                      0,
                      (sum, card) => sum + (card['count'] as int? ?? 0),
                    );
                    final extraCount = deck.extraDeck.fold(
                      0,
                      (sum, card) => sum + (card['count'] as int? ?? 0),
                    );
                    final sideCount = deck.sideDeck.fold(
                      0,
                      (sum, card) => sum + (card['count'] as int? ?? 0),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${deck.deckName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '  Main: $mainCount | Extra: $extraCount | Side: $sideCount',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (results.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('... und ${results.length - 5} weitere'),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alle Decks werden gegen die TCG Bannlist validiert. Verbotene Karten werden entfernt, überzählige Kopien reduziert.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: Text('${results.length} Deck(s) importieren'),
              ),
            ],
          );
        },
      );

      if (shouldImport != true) return;

      // Zeige Progress Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Importiere Decks...'),
              ],
            ),
          );
        },
      );

      // Importiere alle Decks nacheinander
      int successCount = 0;
      int failCount = 0;
      List<String> failedDecks = [];

      for (var ydkResult in results) {
        try {
          await _deckService.createDeck(
            deckName: ydkResult.deckName,
            description:
                'Imported from YDK on ${DateTime.now().toString().split('.')[0]}',
            mainDeck: ydkResult.mainDeck,
            extraDeck: ydkResult.extraDeck,
            sideDeck: ydkResult.sideDeck,
          );
          successCount++;
        } catch (e) {
          print('❌ Fehler beim Speichern von ${ydkResult.deckName}: $e');
          failCount++;
          failedDecks.add(ydkResult.deckName);
        }
      }

      // Schließe Progress Dialog
      if (mounted) Navigator.of(context).pop();

      // Zeige Ergebnis
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Import abgeschlossen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('$successCount Deck(s) erfolgreich importiert'),
                    ],
                  ),
                  if (failCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('$failCount Deck(s) fehlgeschlagen'),
                      ],
                    ),
                    if (failedDecks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Fehlgeschlagene Decks:'),
                      ...failedDecks.map((name) => Text('  • $name')),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Schließe Deck Creation und kehre zur Übersicht zurück
                    widget.onCancel?.call();
                  },
                  child: const Text('Fertig'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ NEU: TXT Export Handler
  Future<void> _handleTxtExport() async {
    if (_mainDeck.isEmpty && _extraDeck.isEmpty && _sideDeck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck ist leer, bitte zuerst Karten hinzufügen'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte zuerst einen Decknamen eingeben'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _ydkImportService.exportDeckAsTxt(
        deckName: deckName,
        mainDeck: _mainDeck,
        extraDeck: _extraDeck,
        sideDeck: _sideDeck,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TXT-Datei erfolgreich gespeichert!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  /// Importiert ein YDK-Deck
  Future<void> _handleYdkImport() async {
    // Zusätzliche Prüfung, um sicherzustellen, dass das Deck leer ist, bevor importiert wird
    if (!isDeckEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('first delelte the deck'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await _ydkImportService.importYdkFile();

      if (result == null) {
        // Benutzer hat Abbruch gedrückt
        return;
      }

      // Bestätigungsdialog anzeigen
      final shouldImport = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          // NEUER STIL: Berechnung der Kartenanzahl
          final mainCount = result.mainDeck.fold(
            0,
            (sum, card) => sum + (card['count'] as int? ?? 0),
          );
          final extraCount = result.extraDeck.fold(
            0,
            (sum, card) => sum + (card['count'] as int? ?? 0),
          );
          final sideCount = result.sideDeck.fold(
            0,
            (sum, card) => sum + (card['count'] as int? ?? 0),
          );

          return AlertDialog(
            title: const Text('import Deck??'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deck: ${result.deckName}'),
                const SizedBox(height: 8),
                Text('Main Deck: $mainCount cards'),
                Text('Extra Deck: $extraCount cards'),
                Text('Side Deck: $sideCount cards'),
                const SizedBox(height: 16),
                const Text(
                  'it will overwrite existing deck.',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('import'),
              ),
            ],
          );
        },
      );

      if (shouldImport == true) {
        setState(() {
          _deckNameController.text = result.deckName;
          _mainDeck = result.mainDeck;
          _extraDeck = result.extraDeck;
          _sideDeck = result.sideDeck;
          _currentDeckId =
              null; // WICHTIG: Neues importiertes Deck hat noch keine DB ID
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.totalCards} Cards imported!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error on Imput: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Exportiert das aktuelle Deck
  Future<void> _handleYdkExport() async {
    // Validiere dass ein Deck vorhanden ist
    if (_mainDeck.isEmpty && _extraDeck.isEmpty && _sideDeck.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck is empty pls add a card first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validiere den Decknamen
    final deckName = _deckNameController.text.trim();
    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pls write a Deckname first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // WICHTIG: Die Logik zur Umwandlung in Bytes muss im YdkImportService sein!
      await _ydkImportService.exportYdkFile(
        deckName: deckName,
        mainDeck: _mainDeck,
        extraDeck: _extraDeck,
        sideDeck: _sideDeck,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('YDK-File sucessfully saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error on Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExportButton() {
    // 🚨 STEUERUNG DER SICHTBARKEIT: Nur anzeigen, wenn das Deck bereits gespeichert wurde
    if (_currentDeckId == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.file_download, size: 20),
      tooltip: 'YDK export',
      onPressed: _handleYdkExport,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildImportButton() {
    // 🚨 STEUERUNG DER SICHTBARKEIT: Nur anzeigen, wenn das Deck leer ist
    if (!isDeckEmpty) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.file_upload, size: 20),
      tooltip: 'YDK export',
      onPressed: _handleYdkImport,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  // Im AppBar Row (nach dem Save-Button):

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error on loading the deck $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? collectDeckDataAndValidate() {
    if (_deckNameController.text.trim().isNotEmpty) {
      return {
        'deckName': _deckNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mainDeck': _mainDeck,
        'extraDeck': _extraDeck,
        'sideDeck': _sideDeck,
        'coverImageUrl': _coverImageUrl,
      };
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A deckname is necesarry')));
    }
    return null;
  }

  void setSaving(bool saving) {
    if (mounted) {
      setState(() => _isSaving = saving);
    }
  }

  void _showCardSearchDialog({bool isSideDeck = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CardSearchDialog(
          isSideDeck: isSideDeck,
          onCardSelected: (card, count) {
            _addCardToDeck(card, count, addToSide: isSideDeck);
          },
          onShowSnackBar: (String message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  void _showCoverImageSelector() {
    final allCards = [..._mainDeck, ..._extraDeck];

    if (allCards.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("First add a Card")));
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pls choose a deckcoverimage'),
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

                return InkWell(
                  onTap: () async {
                    final cardImages = card['card_images'] as List<dynamic>?;

                    if (cardImages == null || cardImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No Image available for: ${card['name']}',
                          ),
                        ),
                      );
                      return;
                    }

                    String? workingUrl;
                    for (var imageEntry in cardImages) {
                      if (imageEntry is Map<String, dynamic>) {
                        // PRIORITÄT: Cropped Image (nur Motiv)
                        final croppedUrl =
                            imageEntry['image_url_cropped'] as String?;
                        if (croppedUrl != null && croppedUrl.isNotEmpty) {
                          try {
                            final downloadUrl = await _cardData.getImgPath(
                              croppedUrl,
                            );
                            if (downloadUrl.isNotEmpty) {
                              workingUrl = croppedUrl;
                              break;
                            }
                          } catch (e) {
                            continue;
                          }
                        }

                        // FALLBACK: Normales Bild
                        final imageUrl = imageEntry['image_url'] as String?;
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          try {
                            final downloadUrl = await _cardData.getImgPath(
                              imageUrl,
                            );
                            if (downloadUrl.isNotEmpty) {
                              workingUrl = imageUrl;
                              break;
                            }
                          } catch (e) {
                            continue;
                          }
                        }
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
                            'Cover-has been set to "${card['name']}"',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'no working image url found for ${card['name']}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      // RUNDES COVER-BILD in der Auswahl
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: ClipOval(
                          child: _CardImageWidget(
                            card: card,
                            cardData: _cardData,
                            fit: BoxFit.cover,
                            useCroppedImage: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['name'] ?? 'unknown',

                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addCardToDeck(
    Map<String, dynamic> card,
    int count, {
    bool addToSide = false,
  }) {
    final frameType = (card['frameType'] as String? ?? '').toLowerCase();
    List<Map<String, dynamic>> targetDeck;

    if (addToSide) {
      targetDeck = _sideDeck;
    } else if (frameType == 'fusion' ||
        frameType == 'synchro' ||
        frameType == 'xyz' ||
        frameType == 'link') {
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
              'Limit over! ${card['name']} you are only allowed to play $maxAllowed copies',
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
              'Limit over! ${card['name']} you are only allowed to play $maxAllowed copies',
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${card['name']} ${count}x added')));
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
          title: const Text('Card deleted'),
          content: Text(
            'How many Cards  do you want to delete from "${card['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('cancel'),
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
    widget.onDetailViewChanged?.call(true);
  }

  Widget _buildDeckSection({
    required String title,
    required List<Map<String, dynamic>> deck,
  }) {
    if (deck.isEmpty) {
      return Center(child: Text('No Cards at $title'));
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
            child: Text('$categoryName ($totalCount)'),
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
                          child: Text('${count}x'),
                        ),
                        const SizedBox(width: 8),
                        _CardImageWidget(card: card, cardData: _cardData),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
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
    return Card(
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
              label = 'COMMENTS';
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
        title = 'Comments';
        if (_currentDeckId == null) {
          return const Center(
            child: Text(
              'You have to save the deck before showing the comments',
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text('$title ($totalCards Cards)'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showCardSearchDialog(isSideDeck: false),
                tooltip: 'Add card',
              ),
              if (currentType != DeckType.comments)
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  color: Colors.orange,
                  onPressed: () => _showCardSearchDialog(isSideDeck: true),
                  tooltip: 'add to sidedeck',
                ),
            ],
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

  Future<void> _handleSave() async {
    final deckData = collectDeckDataAndValidate();

    if (deckData == null) return;

    setState(() => _isSaving = true);

    try {
      if (_currentDeckId == null) {
        final newDeckId = await _deckService.createDeck(
          deckName: deckData['deckName'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
          coverImageUrl: deckData['coverImageUrl'],
        );

        setState(() {
          _currentDeckId = newDeckId;
        });
      } else {
        await _deckService.updateDeck(
          deckId: _currentDeckId!,
          deckName: deckData['deckName'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
          coverImageUrl: deckData['coverImageUrl'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deck sucessfull saved!')));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error on saving: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _handleCancel() {
    if (_mainDeck.isNotEmpty || _extraDeck.isNotEmpty || _sideDeck.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('discard changes?'),
            content: const Text(
              'Do you really want to cancel editing? Unsaved changes will be lost',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onCancel?.call();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('cancel'),
              ),
            ],
          );
        },
      );
    } else {
      widget.onCancel?.call();
    }
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
          widget.onDetailViewChanged?.call(false);
        },
      );
    }

    if (_isLoading || _isSaving) {
      return const Center(child: CircularProgressIndicator());
    }

   
        // ✅ NEUER KOMPAKTER HEADER
      return Column(
      children: [
        // ✅ AKTUALISIERTER HEADER
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Cover Image
                GestureDetector(
                  onTap: _showCoverImageSelector,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: _coverImageUrl != null
                          ? FutureBuilder<String>(
                              future: _cardData.getCorrectImgPath([
                                _coverImageUrl!,
                              ]),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  return Image.network(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.error_outline,
                                          size: 16,
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 16,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Deck Name Input
                Expanded(
                  child: TextField(
                    controller: _deckNameController,
                    decoration: const InputDecoration(
                      hintText: "deckname...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),

                // ✅ Cancel Button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                  tooltip: 'Cancel',
                  onPressed: _handleCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                // ✅ Save Button
                IconButton(
                  icon: const Icon(Icons.save, size: 20),
                  color: Colors.green,
                  tooltip: 'Save',
                  onPressed: _handleSave,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                // ✅ Multi-Import Button (nur wenn Deck leer UND noch nicht gespeichert)
                if (isDeckEmpty && _currentDeckId == null)
                  IconButton(
                    icon: const Icon(Icons.upload_file, size: 20),
                    color: Colors.blue,
                    tooltip: 'YDK Multi-Import',
                    onPressed: _handleMultiYdkImport,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                // ✅ YDK Export (nur wenn Deck gespeichert)
                if (_currentDeckId != null)
                  IconButton(
                    icon: const Icon(Icons.file_download, size: 20),
                    color: Colors.purple,
                    tooltip: 'YDK Export',
                    onPressed: _handleYdkExport,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                // ✅ TXT Export (nur wenn Deck gespeichert)
                if (_currentDeckId != null)
                  IconButton(
                    icon: const Icon(Icons.description, size: 20),
                    color: Colors.orange,
                    tooltip: 'TXT Export',
                    onPressed: _handleTxtExport,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),

                // 🚨 SICHTBARKEITSLOGIK FÜR IMPORTE/EXPORTE
               

        // ✅ KOMPAKTE DECK STATS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              Text('Main: ${_getDeckCardCount(_mainDeck)}'),
              const SizedBox(width: 8),
              Text('Extra: ${_getDeckCardCount(_extraDeck)}'),
              const SizedBox(width: 8),
              Text('Side: ${_getDeckCardCount(_sideDeck)}'),
            ],
          ),
        ),

        // Tabs (unverändert)
        _buildDeckTypeTabs(),

        // MEHR PLATZ FÜR DIE KARTENLISTE!
        Expanded(child: _buildDynamicDeckView()),
      ],
    );
  }

  int _getDeckCardCount(List<Map<String, dynamic>> deck) {
    return deck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
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
        ).showSnackBar(const SnackBar(content: Text('Add comment')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
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
        ).showSnackBar(const SnackBar(content: Text('comment deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error: $e')));
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
          Text('Comments'),
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
            stream: _deckService.getComments(widget.deckId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('error: ${snapshot.error}');
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

                  final canDelete = currentUserId == userId;

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

// ============================================================================
// Card Image Widget
// ============================================================================

class _CardImageWidget extends StatefulWidget {
  final Map<String, dynamic> card;
  final CardData cardData;
  final BoxFit fit;
  final bool useCroppedImage;

  const _CardImageWidget({
    required this.card,
    required this.cardData,
    this.fit = BoxFit.cover,
    this.useCroppedImage = false,
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
        if (widget.useCroppedImage) {
          final croppedUrl = imageEntry['image_url_cropped'] as String?;
          if (croppedUrl != null && croppedUrl.isNotEmpty) {
            allImageUrls.add(croppedUrl);
          }
        }

        final normalUrl = imageEntry['image_url'] as String?;
        if (normalUrl != null && normalUrl.isNotEmpty) {
          allImageUrls.add(normalUrl);
        }

        final smallUrl = imageEntry['image_url_small'] as String?;
        if (smallUrl != null && smallUrl.isNotEmpty) {
          allImageUrls.add(smallUrl);
        }

        if (widget.useCroppedImage) {
          final normalUrl = imageEntry['image_url'] as String?;
          if (normalUrl != null && normalUrl.isNotEmpty) {
            allImageUrls.add(normalUrl);
          }
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
