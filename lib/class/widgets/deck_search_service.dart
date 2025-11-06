// TODO Implement this library.
// deck_search_service.dart - Service für Deck-Suche
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache für Suchergebnisse
  static final Map<String, List<Map<String, dynamic>>> _searchCache = {};

  /// Sucht nach Decks basierend auf Name oder Archetyp
  Future<List<Map<String, dynamic>>> searchDecks(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    // Cache-Check
    if (_searchCache.containsKey(normalizedQuery)) {
      return _searchCache[normalizedQuery]!;
    }

    try {
      // Suche in Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .where('searchTokens', arrayContains: normalizedQuery)
          .limit(100)
          .get();

      final List<Map<String, dynamic>> decks = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Zusätzliche Filterung für bessere Matches
      final filteredDecks = decks.where((deck) {
        final deckName = (deck['deckName'] as String? ?? '').toLowerCase();
        final archetype = (deck['archetype'] as String? ?? '').toLowerCase();
        final littleName = (deck['littleName'] as String? ?? '').toLowerCase();

        return deckName.contains(normalizedQuery) ||
            archetype.contains(normalizedQuery) ||
            littleName.contains(normalizedQuery);
      }).toList();

      // Nach Name sortieren
      filteredDecks.sort((a, b) {
        final nameA = a['deckName'] as String? ?? '';
        final nameB = b['deckName'] as String? ?? '';
        return nameA.compareTo(nameB);
      });

      // Cache speichern
      _searchCache[normalizedQuery] = filteredDecks;

      return filteredDecks;
    } catch (e) {
      print('Fehler bei Deck-Suche: $e');
      return [];
    }
  }

  /// Lädt alle öffentlichen Decks (für Meta-Ansicht)
  Future<List<Map<String, dynamic>>> getAllDecks({int limit = 50}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Fehler beim Laden aller Decks: $e');
      return [];
    }
  }

  /// Lädt ein einzelnes Deck
  Future<Map<String, dynamic>?> getDeck(String deckId) async {
    try {
      final doc = await _firestore.collection('decks').doc(deckId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Fehler beim Laden des Decks: $e');
      return null;
    }
  }

  /// Löscht den Cache
  void clearCache() {
    _searchCache.clear();
  }
}
