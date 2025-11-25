// deck_search_service.dart - KORRIGIERTE VERSION
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sucht nach Decks basierend auf Name, Archetyp oder Beschreibung
  Future<List<Map<String, dynamic>>> searchDecks(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return [];
    }

    final normalizedSearch = searchTerm.trim().toLowerCase();

    try {
      // Suche über searchTokens
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .where('searchTokens', arrayContains: normalizedSearch)
          .limit(50)
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Falls keine Ergebnisse über searchTokens, versuche Teilstring-Suche
      if (results.isEmpty) {
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

        // Exakte Übereinstimmung im Namen hat höchste Priorität
        if (aName == normalizedSearch) return -1;
        if (bName == normalizedSearch) return 1;

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
      return getRecentDecks();
    }
  }

  /// Sucht nach Decks eines bestimmten Archetyps - KORRIGIERTE VERSION
  Future<List<Map<String, dynamic>>> searchDecksByArchetype(
    String? archetype,
  ) async {
    // ✅ NEU: Wenn archetype null oder leer ist, zeige alle Decks
    if (archetype == null || archetype.trim().isEmpty) {
      return getAllDecks();
    }

    final normalizedArchetype = archetype.trim().toLowerCase();
    print('🔍 Suche nach Archetype: $normalizedArchetype');

    try {
      // VERBESSERTE SUCHE: Suche in archetype Feld mit Teilstring
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .where('searchTokens', arrayContains: normalizedArchetype)
          .limit(50)
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print(
              '📋 Gefundenes Deck: ${data['deckName']} - Archetype: ${data['archetype']}',
            );
            return data;
          })
          .where((deck) {
            final deckArchetype = (deck['archetype'] as String? ?? '')
                .toLowerCase();
            // Prüfe ob der Archetype den gesuchten Wert enthält
            final containsArchetype = deckArchetype.contains(
              normalizedArchetype,
            );
            print(
              '🔎 Prüfe Deck "${deck['deckName']}": $deckArchetype enthält $normalizedArchetype? $containsArchetype',
            );
            return containsArchetype;
          })
          .toList();

      print('📊 Anzahl gefundener Decks: ${results.length}');

      // Falls keine Ergebnisse, versuche clientseitige Suche
      if (results.isEmpty) {
        print('🔄 Fallback: Clientseitige Suche...');
        final QuerySnapshot allDecks = await _firestore
            .collection('decks')
            .limit(100)
            .get();

        results = allDecks.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((deck) {
              final deckArchetype = (deck['archetype'] as String? ?? '')
                  .toLowerCase();
              final containsArchetype = deckArchetype.contains(
                normalizedArchetype,
              );
              print(
                '🔎 Fallback-Prüfung: $deckArchetype enthält $normalizedArchetype? $containsArchetype',
              );
              return containsArchetype;
            })
            .toList();

        print('📊 Anzahl gefundener Decks (Fallback): ${results.length}');
      }

      // Sortiere alphabetisch nach Deck-Namen
      results.sort((a, b) {
        final aName = (a['deckName'] as String? ?? '').toLowerCase();
        final bName = (b['deckName'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

      return results;
    } catch (e) {
      print('❌ Fehler bei Archetyp-Suche: $e');
      return [];
    }
  }

  /// ✅ NEU: Lädt alle Decks (für "All archetypes")
  Future<List<Map<String, dynamic>>> getAllDecks() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Fehler beim Laden aller Decks: $e');
      return [];
    }
  }

  /// Lädt die neuesten Decks
  Future<List<Map<String, dynamic>>> getRecentDecks() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Fehler beim Laden der neuesten Decks: $e');
      return [];
    }
  }

  /// Lädt alle verfügbaren Archetypen aus den Decks - KORRIGIERTE VERSION
  Future<List<String>> getAllArchetypes() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('decks')
          .limit(1000) // Erhöhtes Limit für mehr Archetypen
          .get();

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

      final List<String> sortedArchetypes = archetypes.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      print('📋 Gefundene Archetypen: ${sortedArchetypes.length}');
      print('🎯 Archetypen Liste: $sortedArchetypes');

      return sortedArchetypes;
    } catch (e) {
      print('Fehler beim Laden der Archetypen: $e');
      return [];
    }
  }
}
