// deck_search_service.dart - MIT FUNKTIONIERENDER ARCHETYP-SUCHE
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sucht nach Decks basierend auf Name, Archetyp oder Beschreibung
  ///
  /// Die Suche funktioniert über searchTokens (einzelne Wörter)
  Future<List<Map<String, dynamic>>> searchDecks(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    final normalizedSearch = searchTerm.trim().toLowerCase();

    try {
      // Suche über searchTokens - das funktioniert besser für einzelne Wörter
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .where('searchTokens', arrayContains: normalizedSearch)
          .limit(100)
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Falls keine Ergebnisse über searchTokens, versuche Teilstring-Suche
      if (results.isEmpty) {
        // Lade alle Decks und filtere clientseitig (nur für kleine Datenmengen!)
        final QuerySnapshot allDecks = await _firestore
            .collection('decks')
            .limit(100)
            .get();

        results = allDecks.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((deck) {
              final deckName = (deck['deckName'] as String? ?? '')
                  .toLowerCase();
              final archetype = (deck['archetype'] as String? ?? '')
                  .toLowerCase();
              final description = (deck['description'] as String? ?? '')
                  .toLowerCase();

              return deckName.contains(normalizedSearch) ||
                  archetype.contains(normalizedSearch) ||
                  description.contains(normalizedSearch);
            })
            .toList();
      }

      // Sortiere Ergebnisse nach Relevanz
      results.sort((a, b) {
        final aName = (a['deckName'] as String? ?? '').toLowerCase();
        final bName = (b['deckName'] as String? ?? '').toLowerCase();
        final aArchetype = (a['archetype'] as String? ?? '').toLowerCase();
        final bArchetype = (b['archetype'] as String? ?? '').toLowerCase();

        // Exakte Übereinstimmung im Namen hat höchste Priorität
        if (aName == normalizedSearch) return -1;
        if (bName == normalizedSearch) return 1;

        // Dann exakte Übereinstimmung im Archetyp
        if (aArchetype.contains(normalizedSearch) &&
            !bArchetype.contains(normalizedSearch)) {
          return -1;
        }
        if (!aArchetype.contains(normalizedSearch) &&
            bArchetype.contains(normalizedSearch)) {
          return 1;
        }

        // Name beginnt mit Suchbegriff
        if (aName.startsWith(normalizedSearch) &&
            !bName.startsWith(normalizedSearch)) {
          return -1;
        }
        if (!aName.startsWith(normalizedSearch) &&
            bName.startsWith(normalizedSearch)) {
          return 1;
        }

        // Sonst alphabetisch nach Namen
        return aName.compareTo(bName);
      });

      return results;
    } catch (e) {
      print('Fehler bei Deck-Suche: $e');
      return [];
    }
  }

  /// Sucht nach Decks eines bestimmten Archetyps
  ///
  /// Findet alle Decks, die diesen Archetyp enthalten
  Future<List<Map<String, dynamic>>> searchDecksByArchetype(
    String archetype,
  ) async {
    if (archetype.trim().isEmpty) {
      return [];
    }

    final normalizedArchetype = archetype.trim().toLowerCase();

    try {
      // Suche über searchTokens
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .where('searchTokens', arrayContains: normalizedArchetype)
          .limit(100)
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((deck) {
            final deckArchetype = (deck['archetype'] as String? ?? '')
                .toLowerCase();
            return deckArchetype.contains(normalizedArchetype);
          })
          .toList();

      // Falls keine Ergebnisse, versuche clientseitige Suche
      if (results.isEmpty) {
        final QuerySnapshot allDecks = await _firestore
            .collection('decks')
            .limit(100)
            .get();

        results = allDecks.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((deck) {
              final deckArchetype = (deck['archetype'] as String? ?? '')
                  .toLowerCase();
              return deckArchetype.contains(normalizedArchetype);
            })
            .toList();
      }

      // Sortiere alphabetisch nach Deck-Namen
      results.sort((a, b) {
        final aName = (a['deckName'] as String? ?? '').toLowerCase();
        final bName = (b['deckName'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

      return results;
    } catch (e) {
      print('Fehler bei Archetyp-Suche: $e');
      return [];
    }
  }

  /// Lädt die neuesten Decks
  Future<List<Map<String, dynamic>>> getRecentDecks({int limit = 20}) async {
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
      print('Fehler beim Laden der neuesten Decks: $e');
      return [];
    }
  }

  /// Lädt alle verfügbaren Archetypen aus den Decks
  Future<List<String>> getAllArchetypes() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('decks').get();

      final Set<String> archetypes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final archetype = data['archetype'] as String? ?? '';

        if (archetype.isNotEmpty) {
          // Trenne mehrere Archetypen (falls mit Komma getrennt)
          final archetypeList = archetype
              .split(',')
              .map((a) => a.trim())
              .where((a) => a.isNotEmpty);
          archetypes.addAll(archetypeList);
        }
      }

      final List<String> sortedArchetypes = archetypes.toList()..sort();
      return sortedArchetypes;
    } catch (e) {
      print('Fehler beim Laden der Archetypen: $e');
      return [];
    }
  }
}
