// ============================================================================
// lib/class/Firebase/deck/deck_service.dart
// KOMPLETTE DATEI - KORRIGIERT: Karten-Button hinzugefügt, State öffentlich
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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

    // Stellen Sie sicher, dass 'mainDeck', 'extraDeck' usw. enthalten sind.
    return docSnapshot.data()!;
  }

  Future<void> updateDeck({
    required String deckId, // Wichtig: ID des zu aktualisierenden Decks
    required String deckName,
    required String archetype,
    required String description,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final searchIndex = _generateSearchIndex(deckName, archetype, description);
    final searchTokens = _generateSearchTokens(
      deckName,
      archetype,
      description,
    );

    // Aktualisiert das Dokument mit der gegebenen deckId
    await _firestore.collection('decks').doc(deckId).update({
      'deckName': deckName,
      'archetype': archetype,
      'description': description,
      'mainDeck': mainDeck,
      'extraDeck': extraDeck,
      'sideDeck': sideDeck,
      'searchIndex': searchIndex,
      'searchTokens': searchTokens,
      'updatedAt': FieldValue.serverTimestamp(), // Aktualisiere Zeitstempel
    });
  }

  Future<bool> isDeckNameDuplicate({
    required String deckName,
    required String deckNameLower,
    String? excludeDeckId, // Die ID des zu ignorierenden Decks beim Bearbeiten
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Benutzer nicht angemeldet');
    }

    final decksRef = _firestore.collection('decks');
    deckName = deckName.trim().toLowerCase();
    // 1. Suche nach allen Decks des Benutzers mit diesem Namen
    QuerySnapshot snapshot = await decksRef
        .where('deckName', isEqualTo: deckName)
        .where('littleName', isEqualTo: deckNameLower)
        .get();

    // 2. Prüfe die Ergebnisse
    for (var doc in snapshot.docs) {
      final deckData = doc.data() as Map<String, dynamic>; // Sicherer Cast
      final foundDeckId = deckData['deckId'] as String;

      // Wenn kein excludeDeckId gegeben ist (ERSTELLEN) ODER die gefundene
      // ID NICHT der ausgeschlossenen ID entspricht (BEARBEITEN),
      // dann ist es ein Duplikat.
      if (excludeDeckId == null || foundDeckId != excludeDeckId) {
        return true; // Duplikat gefunden!
      }
    }

    return false; // Kein Duplikat gefunden, oder nur das eigene Deck wurde gefunden.
  }

  /// Erstellt ein neues Deck in Firestore
  Future<String> createDeck({
    required String deckName,
    required String archetype,
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
      // WICHTIG: Wirft eine Exception, die in user_profile_side.dart abgefangen wird.
      throw Exception(
        'A Deck with "$deckName" already exists. Please choose a different name.',
      );
    }
    final deckId = _uuid.v4();
    final searchIndex = _generateSearchIndex(deckName, archetype, description);
    final searchTokens = _generateSearchTokens(
      deckName,
      archetype,
      description,
    );

    await _firestore.collection('decks').doc(deckId).set({
      'deckId': deckId,
      'userId': user.uid,
      'username': user.displayName ?? user.email,
      'littleName': deckNameLower,
      'deckName': deckName,
      'archetype': archetype,
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

  // Hilfsmethoden für die Suche
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

  // ANNAHME: Ihre readDeck und updateDeck Methoden existieren hier ebenfalls.
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
  final _archetypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _mainDeck = [];
  List<Map<String, dynamic>> _extraDeck = [];
  List<Map<String, dynamic>> _sideDeck = [];

  final DeckService _deckService = DeckService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentDeckId;

  @override
  void initState() {
    super.initState();
    _currentDeckId = widget.initialDeckId;
    _loadDeckData();
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    _archetypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDeckData() async {
    if (_currentDeckId == null) {
      // Wenn keine ID vorhanden, sind wir im Erstellungsmodus
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Daten aus Firestore lesen
      final deck = await _deckService.readDeck(_currentDeckId!);

      // Controller und Listen mit geladenen Daten füllen
      _deckNameController.text = deck['deckName'] as String;
      _archetypeController.text = deck['archetype'] as String;
      _descriptionController.text = deck['description'] as String;

      // Decks listen (sichere Umwandlung)
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

      // WICHTIG: UI aktualisieren
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fehler anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Decks: $e')),
        );
        // Zurück zur Profilansicht
        // Da die Parent-Klasse keinen direkten Zugriff hat, muss dies über eine
        // Callback-Funktion oder ein State-Management gelöst werden.
        // Fürs Erste setzen wir isLoading, um den Ladekreis zu beenden
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ÖFFENTLICHE METHODE: Vom Parent aufrufbar, um Daten zu sammeln
  Map<String, dynamic>? collectDeckDataAndValidate() {
    if (_formKey.currentState!.validate() &&
        _deckNameController.text.trim().isNotEmpty) {
      final deckData = {
        'deckName': _deckNameController.text.trim(),
        'archetype': _archetypeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mainDeck': _mainDeck,
        'extraDeck': _extraDeck,
        'sideDeck': _sideDeck,
      };

      return deckData;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A Deck must have a Name.')));
    }
    return null;
  }

  // Interne UI-Aktualisierung beim Speichern/Laden
  void setSaving(bool saving) {
    if (mounted) {
      setState(() {
        _isSaving = saving;
      });
    }
  }

  // Hilfsmethode zum Bauen eines Textfeldes

  // Hilfsmethode zum Bauen der Deck-Sektion (MIT KARTE HINZUFÜGEN BUTTON)
  Widget _buildDeckSection({
    required String title,
    required List<Map<String, dynamic>> deck,
    required bool isMainDeck,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // NEU: Row für Titel und Button
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            TextButton.icon(
              onPressed: () {
                // !!! HIER STARTET DIE KARTE-HINZUFÜGEN-LOGIK !!!
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('TODO: Öffne Kartenauswahl für $title-Deck'),
                  ),
                );
                // Sie müssten hier z.B. einen Dialog öffnen und die Ergebnisse
                // der Kartenauswahl zu _mainDeck, _extraDeck oder _sideDeck hinzufügen
              },
              icon: const Icon(Icons.add),
              label: const Text('Karte hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // WICHTIG: ListView.builder MUSS shrinkWrap: true und NeverScrollableScrollPhysics verwenden
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deck.length,
          itemBuilder: (context, index) {
            final card = deck[index];
            return ListTile(
              title: Text(card['name'] ?? 'Unbekannte Karte'),
              trailing: Text('x${card['count'] ?? 0}'),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isSaving) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Form(
        key: _formKey,
        // KORREKTUR: Der äußere Container muss eine Column bleiben
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10), // NEUE ROW FÜR DIE TEXTFELDER (nebeneinander)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Textfeld
                //1: Deck Name
                Expanded(
                  child: TextField(
                    controller: _deckNameController,
                    decoration: InputDecoration(
                      labelText: 'Deck Name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Horizontaler Abstand
                // Textfeld 2: Archetyp
                Expanded(
                  child: TextField(
                    controller: _archetypeController,
                    decoration: InputDecoration(
                      labelText: 'Archetyp',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), // Vertikaler Abstand
            // Textfeld 3: Beschreibung (Bleibt unterhalb der ersten zwei Felder)
            const SizedBox(height: 24), // Vertikaler Abstand
            // Deck Sektionen (Diese waren vorher in der äußeren Column und bleiben dort)
            _buildDeckSection(
              title: 'Main Deck',
              deck: _mainDeck,
              isMainDeck: true,
            ),
            _buildDeckSection(
              title: 'Extra Deck',
              deck: _extraDeck,
              isMainDeck: false,
            ),
            _buildDeckSection(
              title: 'Side Deck',
              deck: _sideDeck,
              isMainDeck: false,
            ),
            const SizedBox(height: 24),

            // CommentSection bleibt auch in der Column
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

class CommentSection extends StatelessWidget {
  final String deckId;
  const CommentSection({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    // ... Ihre Implementierung der CommentSection ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 120),
        Text('Kommentare', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Container(
          height: 50,
          color: Theme.of(context).textTheme.bodyMedium!.color,
          child: const Center(
            child: Text('Kommentarsektion für existierendes Deck'),
          ),
        ),
      ],
    );
  }
}
