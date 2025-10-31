// getCardData.dart (KORRIGIERT für flexible Typ-Suche mit OR-Klauseln + Operatoren + Archetype)

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

  String? _normalizeType(String? type) {
    if (type == null || type.isEmpty) {
      return null;
    }

    final lowerType = type.toLowerCase();

    if (lowerType.contains('pendulum')) {
      return 'Pendulum';
    }

    if (lowerType.contains('ritual')) {
      return 'Ritual Monster';
    }

    if (lowerType.contains('fusion')) {
      return 'Fusion Monster';
    }

    if (lowerType.contains('synchro')) {
      return 'Synchro Monster';
    }

    if (lowerType.contains('xyz')) {
      return 'XYZ Monster';
    }

    if (lowerType.contains('link')) {
      return 'Link Monster';
    }

    if (lowerType.contains('effect monster') ||
        lowerType.contains('tuner') ||
        lowerType.contains('flip') ||
        lowerType.contains('spirit') ||
        lowerType.contains('toon') ||
        lowerType.contains('union') ||
        lowerType.contains('gemini')) {
      return 'Effect Monster';
    }

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

    return _searchAlgolia(suchfeld, null);
  }

  // --- HAUPSUCHE MIT FILTERN (AKTUALISIERT mit Operatoren + Archetype) ---

  Future<List<Map<String, dynamic>>> searchWithFilters({
    String? type,
    String? race,
    String? attribute,
    String? archetype, // NEU: Archetype-Filter
    int? level,
    int? linkRating,
    String? linkRatingOperator,
    int? scale,
    String? scaleOperator,
    String? atk,
    String? def,
    String? banlistTCG,
    String? banlistOCG,
  }) async {
    List<String> facetFilters = [];
    List<String> numericFilters = [];

    // 1. Typ-Filter
    if (type != null && type.isNotEmpty) {
      String searchKeyword = type;

      if (type.contains('Gemini'))
        searchKeyword = 'Gemini';
      else if (type.contains('Flip'))
        searchKeyword = 'Flip';
      else if (type.contains('Spirit'))
        searchKeyword = 'Spirit';
      else if (type.contains('Tuner'))
        searchKeyword = 'Tuner';
      else if (type.contains('Union'))
        searchKeyword = 'Union';
      else if (type.contains('Toon'))
        searchKeyword = 'Toon';
      else if (type.contains('Ritual'))
        searchKeyword = 'Ritual';
      else if (type.contains('Fusion'))
        searchKeyword = 'Fusion';
      else if (type.contains('Synchro'))
        searchKeyword = 'Synchro';
      else if (type.contains('XYZ'))
        searchKeyword = 'XYZ';
      else if (type.contains('Link'))
        searchKeyword = 'Link';
      else if (type.contains('Pendulum'))
        searchKeyword = 'Pendulum';
      else if (type.contains('Effect'))
        searchKeyword = 'Effect';
      else if (type.contains('Normal'))
        searchKeyword = 'Normal';
      else if (type.contains('Spell'))
        searchKeyword = 'Spell';
      else if (type.contains('Trap'))
        searchKeyword = 'Trap';
      else if (type.contains('Token'))
        searchKeyword = 'Token';
      else if (type.contains('Skill'))
        searchKeyword = 'Skill';

      return await _searchAlgoliaWithTypeQuery(
        searchKeyword,
        facetFilters,
        numericFilters,
        race,
        attribute,
        archetype, // NEU: Archetype übergeben
        level,
        linkRating,
        linkRatingOperator,
        scale,
        scaleOperator,
        atk,
        def,
        banlistTCG,
        banlistOCG,
      );
    }

    // 2. Weitere Facettenfilter
    if (race != null && race.isNotEmpty) {
      facetFilters.add('race:$race');
    }
    if (attribute != null && attribute.isNotEmpty) {
      facetFilters.add('attribute:$attribute');
    }
    // NEU: Archetype-Filter
    if (archetype != null && archetype.isNotEmpty) {
      facetFilters.add('archetype:$archetype');
    }
    if (banlistTCG != null && banlistTCG.isNotEmpty) {
      facetFilters.add('banlist_info.ban_tcg:$banlistTCG');
    }
    if (banlistOCG != null && banlistOCG.isNotEmpty) {
      facetFilters.add('banlist_info.ban_ocg:$banlistOCG');
    }

    // 3. Numerische Filter mit Operatoren
    if (level != null) {
      numericFilters.add('level=$level');
    }

    // LinkRating mit Operator
    if (linkRating != null) {
      final op = linkRatingOperator ?? '=';
      numericFilters.add('linkval$op$linkRating');
    }

    // Scale mit Operator
    if (scale != null) {
      final op = scaleOperator ?? '=';
      numericFilters.add('scale$op$scale');
    }

    // ATK - Format: "=1000" oder ">=2000" oder "<=500"
    if (atk != null && atk.isNotEmpty && atk != '?') {
      numericFilters.add('atk$atk');
    }

    // DEF - Format: "=1000" oder ">=2000" oder "<=500"
    if (def != null && def.isNotEmpty && def != '?') {
      numericFilters.add('def$def');
    }

    final result = await _searchAlgoliaWithFilters(
      facetFilters,
      numericFilters,
      typeFilters: [],
      query: null,
    );

    return result;
  }

  // Neue Hilfsmethode für Typ-Suche mit Query (AKTUALISIERT mit Archetype)
  Future<List<Map<String, dynamic>>> _searchAlgoliaWithTypeQuery(
    String typeKeyword,
    List<String> facetFilters,
    List<String> numericFilters,
    String? race,
    String? attribute,
    String? archetype,
    int? level,
    int? linkRating,
    String? linkRatingOperator,
    int? scale,
    String? scaleOperator,
    String? atk,
    String? def,
    String? banlistTCG,
    String? banlistOCG,
  ) async {
    try {
      // 1. Facettenfilter (Dynamisch und kompakt)
      final List<String> newFacetFilters = [
        // Einfache Facetten-Filter
        if (race != null && race.isNotEmpty) 'race:$race',
        if (attribute != null && attribute.isNotEmpty) 'attribute:$attribute',
        if (archetype != null && archetype.isNotEmpty) 'archetype:$archetype',

        // Bannlisten-Filter mit spezifischem Pfad
        if (banlistTCG != null && banlistTCG.isNotEmpty)
          'banlist_info.ban_tcg:$banlistTCG',
        if (banlistOCG != null && banlistOCG.isNotEmpty)
          'banlist_info.ban_ocg:$banlistOCG',
      ];

      // Fügt die neu erstellten Filter zu der übergebenen Liste hinzu
      facetFilters.addAll(newFacetFilters);

      // 2. Numerische Filter (Dynamisch und kompakt)
      final List<String> newNumericFilters = [
        // Level
        if (level != null) 'level=$level',

        // Link Rating mit dynamischem Operator
        if (linkRating != null)
          'linkval${linkRatingOperator ?? '='}$linkRating',

        // Scale mit dynamischem Operator
        if (scale != null) 'scale${scaleOperator ?? '='}$scale',

        // ATK und DEF (enthalten den Operator bereits im String)
        if (atk != null && atk.isNotEmpty && atk != '?') 'atk$atk',
        if (def != null && def.isNotEmpty && def != '?') 'def$def',
      ];

      // Fügt die neu erstellten Filter zu der übergebenen Liste hinzu
      numericFilters.addAll(newNumericFilters);

      // 3. Algolia Suche vorbereiten und ausführen
      final List<List<String>>? finalFacetFilters = facetFilters.isEmpty
          ? null
          : facetFilters.map((f) => [f]).toList();

      final String? finalFilters = numericFilters.isEmpty
          ? null
          : numericFilters.join(' AND ');

      print('🔍 Algolia Type Search Debug:');
      print('Type Keyword (Query auf type-Attribut): $typeKeyword');
      print('Facet Filters: $finalFacetFilters');
      print('Numeric Filters: $finalFilters');

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: typeKeyword,
              restrictSearchableAttributes: ['type'],
              facetFilters: finalFacetFilters,
              filters: finalFilters,
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

  // --- HILFSMETHODE FÜR ALGOILA SUCHE MIT FILTERN (ANGEPASST) ---

  Future<List<Map<String, dynamic>>> _searchAlgoliaWithFilters(
    List<String> facetFilters,
    List<String> numericFilters, {
    String? query,
    List<String> typeFilters = const [],
  }) async {
    try {
      final List<List<String>>? finalFacetFilters = facetFilters.isEmpty
          ? null
          : facetFilters.map((f) => [f]).toList();

      List<String> allFilters = numericFilters;

      if (typeFilters.isNotEmpty) {
        for (var typeFilter in typeFilters) {
          allFilters.add(typeFilter);
        }
      }

      final String? finalFilters = allFilters.isEmpty
          ? null
          : allFilters.join(' AND ');

      final String finalQuery = query ?? '';

      print('🔍 Algolia Search Debug:');
      print('Query (Textsuche): $finalQuery');
      print(
        'Facet Filters (Rasse/Attribut/Archetype/Bannliste): $finalFacetFilters',
      );
      print('Filters (Numerisch/Typ): $finalFilters');

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: finalQuery,
              facetFilters: finalFacetFilters,
              filters: finalFilters,
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

  // In getCardData.dart diese Methode hinzufügen:

  // getCardData.dart - Verbesserte getAllArchetypes Methode

  // getCardData.dart - Vollständige getAllArchetypes Methode mit Pagination

  Future<List<String>> getFacetValues(String fieldName) async {
    try {
      print('[v0] Lade Facetten für Feld: $fieldName...');

      // 1. Versuche zuerst Facetten zu laden (Algolia Facet Search)
      try {
        final response = await client.search(
          searchMethodParams: algolia_lib.SearchMethodParams(
            requests: [
              algolia_lib.SearchForHits(
                indexName: 'cards',
                query: '',
                facets: [fieldName], // Dynamischer Feldname
                hitsPerPage: 0,
              ),
            ],
          ),
        );

        final dynamic facetsData = (response.results.first as Map)['facets'];

        if (facetsData != null && facetsData is Map) {
          final Map<String, dynamic> facets = Map<String, dynamic>.from(
            facetsData,
          );
          // Nutze den übergebenen fieldName, um die Facettenwerte abzurufen
          final facetValuesMap = facets[fieldName];

          if (facetValuesMap != null && facetValuesMap is Map) {
            final List<String> values = (facetValuesMap as Map<String, dynamic>)
                .keys
                .where((key) => key != null && key.toString().isNotEmpty)
                .map((key) => key.toString())
                .toList();

            if (values.isNotEmpty) {
              values.sort();
              print('[v0] Facetten für $fieldName erfolgreich geladen.');
              return values;
            }
          }
        }
      } catch (e) {
        print('[v0] Facetten-Laden für $fieldName fehlgeschlagen: $e');
      }

      // 2. Fallback: Lade ALLE Karten mit Pagination und extrahiere Werte

      final Set<String> valuesSet = {};
      int page = 0;
      int hitsPerPage = 1000;
      bool hasMorePages = true;

      while (hasMorePages) {
        final response = await client.search(
          searchMethodParams: algolia_lib.SearchMethodParams(
            requests: [
              algolia_lib.SearchForHits(
                indexName: 'cards',
                query: '',
                hitsPerPage: hitsPerPage,
                page: page,
                attributesToRetrieve: [fieldName], // Dynamischer Feldname
              ),
            ],
          ),
        );

        final dynamic hitsData = (response.results.first as Map)['hits'];
        final int? nbPages = (response.results.first as Map)['nbPages'] as int?;

        if (hitsData == null || hitsData is! List || hitsData.isEmpty) {
          hasMorePages = false;
          break;
        }

        final List<dynamic> hits = hitsData as List;

        for (var hit in hits) {
          if (hit is Map<String, dynamic>) {
            final value = hit[fieldName]; // Dynamischer Feldname
            if (value != null && value.toString().isNotEmpty) {
              valuesSet.add(value.toString());
            }
          }
        }

        // Prüfe ob es weitere Seiten gibt
        if (nbPages != null && page >= nbPages - 1) {
          hasMorePages = false;
        } else if (hits.length < hitsPerPage) {
          hasMorePages = false;
        } else {
          page++;
        }
      }

      final List<String> values = valuesSet.toList();
      values.sort();

      return values;
    } catch (e, stacktrace) {
      print('[v0] Fehler beim Laden der Facetten ($fieldName): $e');
      print('[v0] Stacktrace: $stacktrace');
      return [];
    }
  }
}
