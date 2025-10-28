// getCardData.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';
import 'package:algoliasearch/algoliasearch.dart' as algolia_lib;

// 🛑 WICHTIG: Verwende den Admin Key NUR für Schreibvorgänge (wie updateAlgoliaWithImages)
// Für Lesezugriffe (search) reicht der Search API Key (d1fa622037651adc1672871ca583aab3)
// Da du den Write/Admin Key für Lese- und Schreibvorgänge verwendest, funktioniert es,
// ist aber aus Sicherheitssicht nicht optimal. Ich belasse es für die Funktion deines Skripts.
final algolia_lib.SearchClient client = algolia_lib.SearchClient(
  appId: 'ZFFHWZ011E',
  apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
);

class CardData implements Dbrepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // --- HILFSMETHODE FÜR ALGOILA SUCHE ---

  // Kapselt die Logik für Algolia-Abfragen mit optionalem Suchtext und Filter
  Future<List<Map<String, dynamic>>> _searchAlgolia(
    String? query,
    String? filter,
  ) async {
    print(
      "DEBUG START: _searchAlgolia aufgerufen mit Query: $query, Filter: $filter",
    );

    try {
      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: query,
              filters: filter, // Filter-String für Bannlisten
              hitsPerPage:
                  1000, // Hohe Zahl, um alle Bannlisten-Karten zu erfassen
            ),
          ],
        ),
      );

      // Algolia-Antworten sind Maps, deren Hits-Array wir extrahieren
      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List) {
        return [];
      }

      final List<dynamic> hits = hitsData as List;

      // Konvertiere zu Map-Liste
      final List<Map<String, dynamic>> cards = hits
          .map((hit) => Map<String, dynamic>.from(hit as Map))
          .toList();

      // Client-seitige Sortierung nach Name, falls Algolia-Sortierung nicht genutzt wird
      cards.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );

      print("Algolia erfolgreich erreicht. Gefundene Hits: ${cards.length}");

      return cards;
    } catch (e, stacktrace) {
      print("🚨🚨🚨 ALGO-FEHLER AUFGETRETEN 🚨🚨🚨");
      print("Fehlermeldung: $e");
      print("Stacktrace: $stacktrace");
      print("🚨🚨🚨 ALGO-FEHLER ENDE 🚨🚨🚨");
      return [];
    }
  }

  // --- FIREBASE LESEN (NUR BEI BEDARF/MUSS) ---

  // Diese Methode liest aus Firestore (wird wahrscheinlich nicht mehr benötigt)
  Future<List<Map<String, dynamic>>> getallChards() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Fehler beim Abrufen der Karten: $e");
      return [];
    }
  }

  // --- BANNLISTE (JETZT ALGOILA) ---

  // Ruft TCG-banned Karten über Algolia ab (nutzt Filter)

  Future<List<Map<String, dynamic>>> getTCGBannedCards() async {
    // ⬇️ Wählt nur die relevanten Status, was robuster ist
    final String filter =
        'banlist_info.ban_tcg:Forbidden OR banlist_info.ban_tcg:Limited OR banlist_info.ban_tcg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

  // Ruft OCG-banned Karten über Algolia ab (nutzt Filter)
  Future<List<Map<String, dynamic>>> getOCGBannedCards() async {
    // ⬇️ Wählt nur die relevanten Status, was robuster ist
    final String filter =
        'banlist_info.ban_ocg:Forbidden OR banlist_info.ban_ocg:Limited OR banlist_info.ban_ocg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

  // Sortiert die TCG-Karten nach Bannstatus (nutzt die Algolia-Ergebnisse)
  Future<Map<String, List<dynamic>>> sortTCGBannCards() async {
    List<Map<String, dynamic>> liste = await getTCGBannedCards();
    List<dynamic> banned = [];
    List<dynamic> semiLimited = [];
    List<dynamic> limited = [];

    Map<String, List<dynamic>> sortedList = {};

    for (var element in liste) {
      if (element["banlist_info"] is Map) {
        String? banStatus = element["banlist_info"]["ban_tcg"] as String?;

        if (banStatus == "Forbidden") {
          banned.add(element);
        } else if (banStatus == "Semi-Limited") {
          semiLimited.add(element);
        } else if (banStatus == "Limited") {
          limited.add(element);
        }
      }
    }

    sortedList["limited"] = limited;
    sortedList["banned"] = banned;
    sortedList["semiLimited"] = semiLimited;
    return sortedList;
  }

  // Sortiert die OCG-Karten nach Bannstatus (nutzt die Algolia-Ergebnisse)
  Future<Map<String, List<dynamic>>> sortOCGBannCards() async {
    List<Map<String, dynamic>> liste = await getOCGBannedCards();
    List<dynamic> banned = [];
    List<dynamic> semiLimited = [];
    List<dynamic> limited = [];

    Map<String, List<dynamic>> sortedList = {};

    for (var element in liste) {
      if (element["banlist_info"] is Map) {
        String? banStatus = element["banlist_info"]["ban_ocg"] as String?;

        if (banStatus == "Forbidden") {
          banned.add(element);
        } else if (banStatus == "Semi-Limited") {
          semiLimited.add(element);
        } else if (banStatus == "Limited") {
          limited.add(element);
        }
      }
    }

    sortedList["limited"] = limited;
    sortedList["banned"] = banned;
    sortedList["semiLimited"] = semiLimited;
    return sortedList;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCardsFromBannlist() async {
    return getTCGBannedCards(); // Delegiert an die Algolia-Methode
  }

  // --- ALGOILA SUCHE ---

  // Ruft Ergebnisse anhand eines Suchbegriffs über Algolia ab (nutzt die Hilfsmethode)
  Future<List<Map<String, dynamic>>> ergebniseAnzeigen(String suchfeld) async {
    if (suchfeld.isEmpty) return [];

    return _searchAlgolia(suchfeld, null);
  }

  // --- FIREBASE SPEICHER/HELPER ---

  Future<String> getImgPath(String gsPath) async {
    try {
      final storage = FirebaseStorage.instance;

      final uri = Uri.parse(gsPath);
      final path = Uri.decodeComponent(uri.path.substring(1));

      final Reference gsReference = storage.ref(path);
      final String downloadUrl = await gsReference.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Fehler ($gsPath): ${e.code} - ${e.message}');
      return '';
    } catch (e) {
      print('Allgemeiner Fehler beim Abrufen der URL für $gsPath: $e');
      return '';
    }
  }

  Future<String> getCorrectImgPath(List<String> imageUrls) async {
    const String storageFolder = 'hohe auflösung/';

    for (var imageUrl in imageUrls) {
      if (imageUrl.isEmpty) continue;

      try {
        final uri = Uri.parse(imageUrl);
        final fileName = uri.pathSegments.last;

        final storagePath = storageFolder + fileName;

        final ref = storage.ref().child(storagePath);

        await ref.getMetadata();

        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          continue;
        }
        print("Firebase Storage Fehler: ${e.message}");
        continue;
      } catch (e) {
        print("Fehler beim Prüfen der URL: $e");
        continue;
      }
    }

    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }

    return '';
  }

  // --- ALGOLIA WRITE (ADMIN) ---

  // Aktualisiert Algolia-Index mit Daten aus Firestore
  Future<void> updateAlgoliaWithImages() async {
    final db = FirebaseFirestore.instance;

    // Client für Schreibvorgänge (muss den Admin Key verwenden)
    final writeClient = algolia_lib.SearchClient(
      appId: 'ZFFHWZ011E',
      apiKey: 'bbcc7bed24e11232cbfd76ce9017b629', // Admin API Key
    );

    try {
      print("Starte Aktualisierung der Algolia-Daten mit Bildern...");

      int totalProcessed = 0;
      int batchSize = 500;
      DocumentSnapshot? lastDoc;

      while (true) {
        Query query = db.collection('cards').limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          print("Keine weiteren Dokumente gefunden.");
          break;
        }

        print(
          "Verarbeite Batch ${(totalProcessed / batchSize).floor() + 1} (${snapshot.docs.length} Karten)...",
        );

        final List<Map<String, dynamic>> recordsToUpdate = [];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          final record = {
            'objectID': doc.id,
            'name': data['name'],
            'desc': data['desc'],
            'type': data['type'],
            'race': data['race'],
            'attribute': data['attribute'],
            'atk': data['atk'],
            'def': data['def'],
            'level': data['level'],
            'frameType': data['frameType'],
            'archetype': data['archetype'],
            'scale': data['scale'],
            'linkval': data['linkval'],

            // 🟢 KORREKTUR: banlist_info als Map übernehmen
            'banlist_info': data['banlist_info'] as Map<String, dynamic>? ?? {},
            // 🟢 KORREKTUR: card_images als List übernehmen
            'card_images': (data['card_images'] as List?)?.toList() ?? [],
          };

          recordsToUpdate.add(record);
        }

        // Upload zu Algolia
        await writeClient.batch(
          indexName: 'cards',
          batchWriteParams: algolia_lib.BatchWriteParams(
            requests: recordsToUpdate.map((record) {
              return algolia_lib.BatchRequest(
                action: algolia_lib
                    .Action
                    .addObject, // Fügt hinzu oder überschreibt, wenn objectID existiert
                body: record,
              );
            }).toList(),
          ),
        );

        totalProcessed += snapshot.docs.length;
        lastDoc = snapshot.docs.last;

        print("✅ Batch hochgeladen. Gesamt: $totalProcessed Karten");

        await Future.delayed(Duration(milliseconds: 500));
      }

      print("🎉 Erfolgreich $totalProcessed Karten mit Bildern aktualisiert!");

      writeClient.dispose();
    } catch (e, stacktrace) {
      print("❌ Fehler beim Aktualisieren: $e");
      print("Stacktrace: $stacktrace");
      writeClient.dispose();
    }
  }

  // --- UNIMPLEMENTED METHODS ---

  @override
  Future<void> createDeck() {
    throw UnimplementedError();
  }

  @override
  Future<void> createUser(String username, String email, String userId) {
    throw UnimplementedError();
  }

  @override
  Future<void> readDeck() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> readUser(String userId) {
    throw UnimplementedError();
  }
}
