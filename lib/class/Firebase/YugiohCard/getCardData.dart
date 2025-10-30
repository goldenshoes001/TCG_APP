// getCardData.dart (KORRIGIERT für flexible Typ-Suche mit OR-Klauseln)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';
import 'package:algoliasearch/algoliasearch.dart' as algolia_lib;

final algolia_lib.SearchClient client = algolia_lib.SearchClient(
  appId: 'ZFFHWZ011E',
  apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
);

class CardData implements Dbrepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // --- HILFSMETHODE FÜR ALGOILA SUCHE (Basis) ---

  Future<List<Map<String, dynamic>>> _searchAlgolia(
    String? query,
    String? filter,
  ) async {
    try {
      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: query,
              filters: filter,
              hitsPerPage: 1000,
            ),
          ],
        ),
      );

      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List) {
        return [];
      }

      final List<dynamic> hits = hitsData as List;

      final List<Map<String, dynamic>> cards = hits
          .map((hit) => Map<String, dynamic>.from(hit as Map))
          .toList();

      cards.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );

      return cards;
    } catch (e, stacktrace) {
      return [];
    }
  }

  // --- HILFSMETHODE ZUR TYP-NORMALISIERUNG (UNVERÄNDERT) ---

  // Normalisiert komplexe Typen auf einen Haupttyp (z.B. alle Ritual/Pendulum-Typen auf den Basis-Typ).
  String? _normalizeType(String? type) {
    if (type == null || type.isEmpty) {
      return null;
    }

    final lowerType = type.toLowerCase();

    // Pendulum-Typen zusammenfassen: "Pendulum Effect Monster" -> "Pendulum"
    if (lowerType.contains('pendulum')) {
      return 'Pendulum';
    }

    // Ritual-Typen zusammenfassen: "Ritual Effect Monster" -> "Ritual Monster"
    if (lowerType.contains('ritual')) {
      return 'Ritual Monster';
    }

    // Fusion-Typen zusammenfassen
    if (lowerType.contains('fusion')) {
      return 'Fusion Monster';
    }

    // Synchro-Typen zusammenfassen
    if (lowerType.contains('synchro')) {
      return 'Synchro Monster';
    }

    // XYZ-Typen zusammenfassen
    if (lowerType.contains('xyz')) {
      return 'XYZ Monster';
    }

    // Link-Typen zusammenfassen
    if (lowerType.contains('link')) {
      return 'Link Monster';
    }

    // Basistyp "Effect Monster" für alle, die nicht spezifisch sind
    if (lowerType.contains('effect monster') ||
        lowerType.contains('tuner') ||
        lowerType.contains('flip') ||
        lowerType.contains('spirit') ||
        lowerType.contains('toon') ||
        lowerType.contains('union') ||
        lowerType.contains('gemini')) {
      return 'Effect Monster';
    }

    // Für alle anderen Basistypen (Normal Monster, Spell Card, Trap Card, Token, Skill Card)
    // den Originalwert zurückgeben (der aus der meta.dart Liste kommt).
    return type;
  }

  // --- FIREBASE LESEN (NUR BEI BEDARF/MUSS) ---

  Future<List<Map<String, dynamic>>> getallChards() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  // --- BANNLISTE (JETZT ALGOILA) ---

  Future<List<Map<String, dynamic>>> getTCGBannedCards() async {
    final String filter =
        'banlist_info.ban_tcg:Forbidden OR banlist_info.ban_tcg:Limited OR banlist_info.ban_tcg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

  Future<List<Map<String, dynamic>>> getOCGBannedCards() async {
    final String filter =
        'banlist_info.ban_ocg:Forbidden OR banlist_info.ban_ocg:Limited OR banlist_info.ban_ocg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

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
    return getTCGBannedCards();
  }

  // --- ALGOILA SUCHE ---

  Future<List<Map<String, dynamic>>> ergebniseAnzeigen(String suchfeld) async {
    if (suchfeld.isEmpty) return [];

    // Normale Textsuche, daher wird der Query genutzt
    return _searchAlgolia(suchfeld, null);
  }

  // --- HAUPSUCHE MIT FILTERN (KORRIGIERT) ---

  Future<List<Map<String, dynamic>>> searchWithFilters({
    String? type,
    String? race,
    String? attribute,
    int? level,
    int? linkRating,
    int? scale,
    String? atk,
    String? def,
    String? banlistTCG,
    String? banlistOCG,
  }) async {
    List<String> facetFilters = [];
    List<String> numericFilters = [];
    List<String> typeFilters = []; // Trennung des Typ-Filters

    // 1. Typ-Filter: Normalisierung.
    final String? normalizedType = _normalizeType(type);

    if (normalizedType != null && normalizedType.isNotEmpty) {
      // NEU: Logik zur Erstellung von OR-Filtern für komplexe Typen
      if (normalizedType == 'Ritual Monster') {
        // Sucht nach "Ritual Monster" ODER "Ritual Effect Monster"
        typeFilters.add(
          '(type:"Ritual Monster" OR type:"Ritual Effect Monster")',
        );
      } else if (normalizedType == 'Pendulum') {
        // Sucht nach allen relevanten Pendulum-Unterformen
        typeFilters.add(
          '(type:"Pendulum Effect Monster" OR type:"Pendulum Normal Monster" OR type:"Pendulum Flip Effect Monster" OR type:"Pendulum Effect Fusion Monster" OR type:"Pendulum Effect Synchro Monster" OR type:"Pendulum Effect Xyz Monster")',
        );
      } else if (normalizedType == 'Fusion Monster') {
        typeFilters.add(
          '(type:"Fusion Monster" OR type:"Effect Fusion Monster")',
        );
      } else if (normalizedType == 'Synchro Monster') {
        typeFilters.add(
          '(type:"Synchro Monster" OR type:"Synchro Effect Monster")',
        );
      } else if (normalizedType == 'XYZ Monster') {
        typeFilters.add('(type:"XYZ Monster" OR type:"XYZ Effect Monster")');
      } else if (normalizedType == 'Link Monster') {
        typeFilters.add('(type:"Link Monster" OR type:"Link Effect Monster")');
      } else if (normalizedType == 'Effect Monster') {
        // Sammelt alle Basistypen, die 'Effect Monster' oder eine einfache Variante sind
        typeFilters.add(
          '(type:"Effect Monster" OR type:"Tuner Monster" OR type:"Flip Effect Monster" OR type:"Spirit Monster" OR type:"Toon Monster" OR type:"Union Effect Monster" OR type:"Gemini Monster")',
        );
      } else {
        // Für alle anderen Basistypen (Spell Card, Trap Card, Normal Monster, Token etc.)
        typeFilters.add('type:"$normalizedType"');
      }
    }

    // 2. Weitere Facettenfilter (bleiben als FacetFilters)
    if (race != null && race.isNotEmpty) {
      facetFilters.add('race:$race');
    }
    if (attribute != null && attribute.isNotEmpty) {
      facetFilters.add('attribute:$attribute');
    }
    if (banlistTCG != null && banlistTCG.isNotEmpty) {
      facetFilters.add('banlist_info.ban_tcg:$banlistTCG');
    }
    if (banlistOCG != null && banlistOCG.isNotEmpty) {
      facetFilters.add('banlist_info.ban_ocg:$banlistOCG');
    }

    // 3. Numerische Filter
    if (level != null) {
      numericFilters.add('level=$level');
    }
    if (linkRating != null) {
      numericFilters.add('linkval=$linkRating');
    }
    if (scale != null) {
      numericFilters.add('scale=$scale');
    }
    if (atk != null && atk.isNotEmpty && atk != '?') {
      numericFilters.add('atk=$atk');
    }
    if (def != null && def.isNotEmpty && def != '?') {
      numericFilters.add('def=$def');
    }

    // Ruft die Methode OHNE Query (Textsuche) auf.
    final result = await _searchAlgoliaWithFilters(
      facetFilters,
      numericFilters,
      typeFilters:
          typeFilters, // Übergabe des Typ-Filters, jetzt ein vollständiger Filter-String
      query: null,
    );

    return result;
  }

  // --- HILFSMETHODE FÜR ALGOILA SUCHE MIT FILTERN (ANGEPASST) ---

  Future<List<Map<String, dynamic>>> _searchAlgoliaWithFilters(
    List<String> facetFilters,
    List<String> numericFilters, {
    String? query,
    List<String> typeFilters = const [], // Enthält nun fertige Filter-Strings
  }) async {
    try {
      // Für AND-Verknüpfung: Jeder Facet-Filter in ein eigenes Array
      final List<List<String>>? finalFacetFilters = facetFilters.isEmpty
          ? null
          : facetFilters.map((f) => [f]).toList();

      // Kombinierte Filtermethode (numerisch + Typ)
      List<String> allFilters = numericFilters;

      // Hinzufügen der Typ-Filter (Fertige OR-Strings oder einfache type:"Wert")
      // Die Strings in typeFilters sind bereits fertig formatiert, z.B. '(type:"Ritual Monster" OR type:"Ritual Effect Monster")'
      if (typeFilters.isNotEmpty) {
        for (var typeFilter in typeFilters) {
          allFilters.add(typeFilter);
        }
      }

      final String? finalFilters = allFilters.isEmpty
          ? null
          : allFilters.join(' AND ');

      // Query ist nur gesetzt, wenn es eine Textsuche ist (von ergebniseAnzeigen)
      final String finalQuery = query ?? '';

      // DEBUG: Print was wir an Algolia senden
      print('🔍 Algolia Search Debug:');
      print('Query (Textsuche): $finalQuery');
      print('Facet Filters (Rasse/Attribut/Bannliste): $finalFacetFilters');
      print('Filters (Numerisch/Typ): $finalFilters'); // Typ ist hier enthalten

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: finalQuery,
              facetFilters: finalFacetFilters,
              filters:
                  finalFilters, // HIER wird der flexible Typ-Filter angewandt
              hitsPerPage: 1000,
            ),
          ],
        ),
      );

      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List) {
        print('❌ Keine Hits gefunden');
        return [];
      }

      final List<dynamic> hits = hitsData as List;

      final List<Map<String, dynamic>> cards = hits
          .map((hit) => Map<String, dynamic>.from(hit as Map))
          .toList();

      cards.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );

      print('✅ ${cards.length} Karten gefunden');

      return cards;
    } catch (e, stacktrace) {
      print('❌ Algolia Fehler: $e');
      print('Stacktrace: $stacktrace');
      return [];
    }
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
      return '';
    } catch (e) {
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
        continue;
      } catch (e) {
        continue;
      }
    }

    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }

    return '';
  }

  // --- ALGOLIA WRITE (ADMIN) ---

  Future<void> updateAlgoliaWithImages() async {
    final db = FirebaseFirestore.instance;

    final writeClient = algolia_lib.SearchClient(
      appId: 'ZFFHWZ011E',
      apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
    );

    try {
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
          break;
        }

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

            'banlist_info': data['banlist_info'] as Map<String, dynamic>? ?? {},
            'card_images': (data['card_images'] as List?)?.toList() ?? [],
          };

          recordsToUpdate.add(record);
        }

        await writeClient.batch(
          indexName: 'cards',
          batchWriteParams: algolia_lib.BatchWriteParams(
            requests: recordsToUpdate.map((record) {
              return algolia_lib.BatchRequest(
                action: algolia_lib.Action.addObject,
                body: record,
              );
            }).toList(),
          ),
        );

        totalProcessed += snapshot.docs.length;
        lastDoc = snapshot.docs.last;

        await Future.delayed(Duration(milliseconds: 500));
      }

      writeClient.dispose();
    } catch (e, stacktrace) {
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
