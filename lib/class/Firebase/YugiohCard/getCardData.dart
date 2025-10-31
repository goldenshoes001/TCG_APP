// getCardData.dart - OPTIMIERT MIT IMAGE CACHING UND LEVEL-OPERATOR

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

  // NEU: Image URL Cache
  static final Map<String, String> _imageUrlCache = {};

  // NEU: Batch Loading Queue
  static final Map<String, Future<String>> _loadingQueue = {};

  // --- OPTIMIERTE IMAGE METHODEN ---

  /// Optimierte getImgPath mit Caching und Batch-Loading
  Future<String> getImgPath(String gsPath) async {
    // 1. Prüfe Cache
    if (_imageUrlCache.containsKey(gsPath)) {
      return _imageUrlCache[gsPath]!;
    }

    // 2. Prüfe ob bereits geladen wird
    if (_loadingQueue.containsKey(gsPath)) {
      return await _loadingQueue[gsPath]!;
    }

    // 3. Starte neuen Ladevorgang
    final Future<String> loadFuture = _loadImageUrl(gsPath);
    _loadingQueue[gsPath] = loadFuture;

    try {
      final url = await loadFuture;
      _imageUrlCache[gsPath] = url;
      return url;
    } finally {
      _loadingQueue.remove(gsPath);
    }
  }

  Future<String> _loadImageUrl(String gsPath) async {
    try {
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

  /// Batch-Load mehrerer Bilder parallel
  Future<Map<String, String>> batchLoadImages(List<String> gsPaths) async {
    final Map<String, String> results = {};

    // Filtere bereits gecachte
    final uncached = gsPaths
        .where((p) => !_imageUrlCache.containsKey(p))
        .toList();

    if (uncached.isEmpty) {
      for (var path in gsPaths) {
        results[path] = _imageUrlCache[path]!;
      }
      return results;
    }

    // Lade parallel (max 10 gleichzeitig)
    for (int i = 0; i < uncached.length; i += 10) {
      final batch = uncached.skip(i).take(10).toList();
      final futures = batch.map((path) => getImgPath(path)).toList();
      final urls = await Future.wait(futures);

      for (int j = 0; j < batch.length; j++) {
        results[batch[j]] = urls[j];
      }
    }

    // Füge gecachte hinzu
    for (var path in gsPaths) {
      if (_imageUrlCache.containsKey(path)) {
        results[path] = _imageUrlCache[path]!;
      }
    }

    return results;
  }

  /// Preload für Listen von Karten
  Future<void> preloadCardImages(
    List<Map<String, dynamic>> cards, {
    int maxCards = 50,
  }) async {
    final imagePaths = <String>[];

    for (var card in cards.take(maxCards)) {
      if (card["card_images"] != null &&
          card["card_images"] is List &&
          (card["card_images"] as List).isNotEmpty) {
        final imageUrl = card["card_images"][0]["image_url"];
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          imagePaths.add(imageUrl.toString());
        }
      }
    }

    if (imagePaths.isNotEmpty) {
      await batchLoadImages(imagePaths);
    }
  }

  /// Cache-Verwaltung
  void clearImageCache() {
    _imageUrlCache.clear();
  }

  int getImageCacheSize() => _imageUrlCache.length;

  // --- OPTIMIERTE getCorrectImgPath ---

  Future<String> getCorrectImgPath(List<String> imageUrls) async {
    const String storageFolder = 'hohe auflösung/';

    for (var imageUrl in imageUrls) {
      if (imageUrl.isEmpty) continue;

      // Prüfe Cache zuerst
      final cacheKey = storageFolder + imageUrl;
      if (_imageUrlCache.containsKey(cacheKey)) {
        return _imageUrlCache[cacheKey]!;
      }

      try {
        final uri = Uri.parse(imageUrl);
        final fileName = uri.pathSegments.last;
        final storagePath = storageFolder + fileName;

        final ref = storage.ref().child(storagePath);
        await ref.getMetadata();

        final downloadUrl = await ref.getDownloadURL();

        // Cache speichern
        _imageUrlCache[cacheKey] = downloadUrl;

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

  // --- RESTLICHER CODE BLEIBT GLEICH ---

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

  // --- HELPER METHODEN ---

  String _convertOperator(String operator) {
    switch (operator) {
      case 'min':
        return '>=';
      case 'max':
        return '<=';
      case '=':
      default:
        return '=';
    }
  }

  String? _normalizeType(String? type) {
    if (type == null || type.isEmpty) {
      return null;
    }

    final lowerType = type.toLowerCase();

    if (lowerType.contains('pendulum')) return 'Pendulum';
    if (lowerType.contains('ritual')) return 'Ritual Monster';
    if (lowerType.contains('fusion')) return 'Fusion Monster';
    if (lowerType.contains('synchro')) return 'Synchro Monster';
    if (lowerType.contains('xyz')) return 'XYZ Monster';
    if (lowerType.contains('link')) return 'Link Monster';
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

  Future<List<Map<String, dynamic>>> ergebniseAnzeigen(String suchfeld) async {
    if (suchfeld.isEmpty) return [];
    return _searchAlgolia(suchfeld, null);
  }

  Future<List<Map<String, dynamic>>> searchWithFilters({
    String? type,
    String? race,
    String? attribute,
    String? archetype,
    int? level,
    String? levelOperator,
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
        archetype,
        level,
        levelOperator,
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

    // Facet Filters
    if (race != null && race.isNotEmpty) facetFilters.add('race:$race');
    if (attribute != null && attribute.isNotEmpty)
      facetFilters.add('attribute:$attribute');
    if (archetype != null && archetype.isNotEmpty)
      facetFilters.add('archetype:$archetype');
    if (banlistTCG != null && banlistTCG.isNotEmpty)
      facetFilters.add('banlist_info.ban_tcg:$banlistTCG');
    if (banlistOCG != null && banlistOCG.isNotEmpty)
      facetFilters.add('banlist_info.ban_ocg:$banlistOCG');

    // Numeric Filters
    if (level != null)
      numericFilters.add(
        'level${_convertOperator(levelOperator ?? '=')}$level',
      );
    if (linkRating != null)
      numericFilters.add(
        'linkval${_convertOperator(linkRatingOperator ?? '=')}$linkRating',
      );
    if (scale != null)
      numericFilters.add(
        'scale${_convertOperator(scaleOperator ?? '=')}$scale',
      );
    if (atk != null && atk.isNotEmpty && atk != '?')
      numericFilters.add('atk$atk');
    if (def != null && def.isNotEmpty && def != '?')
      numericFilters.add('def$def');

    return await _searchAlgoliaWithFilters(
      facetFilters,
      numericFilters,
      typeFilters: [],
      query: null,
    );
  }

  Future<List<Map<String, dynamic>>> _searchAlgoliaWithTypeQuery(
    String typeKeyword,
    List<String> facetFilters,
    List<String> numericFilters,
    String? race,
    String? attribute,
    String? archetype,
    int? level,
    String? levelOperator,
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
      final List<String> newFacetFilters = [
        if (race != null && race.isNotEmpty) 'race:$race',
        if (attribute != null && attribute.isNotEmpty) 'attribute:$attribute',
        if (archetype != null && archetype.isNotEmpty) 'archetype:$archetype',
        if (banlistTCG != null && banlistTCG.isNotEmpty)
          'banlist_info.ban_tcg:$banlistTCG',
        if (banlistOCG != null && banlistOCG.isNotEmpty)
          'banlist_info.ban_ocg:$banlistOCG',
      ];

      facetFilters.addAll(newFacetFilters);

      final List<String> newNumericFilters = [
        if (level != null)
          'level${_convertOperator(levelOperator ?? '=')}$level',
        if (linkRating != null)
          'linkval${_convertOperator(linkRatingOperator ?? '=')}$linkRating',
        if (scale != null)
          'scale${_convertOperator(scaleOperator ?? '=')}$scale',
        if (atk != null && atk.isNotEmpty && atk != '?') 'atk$atk',
        if (def != null && def.isNotEmpty && def != '?') 'def$def',
      ];

      numericFilters.addAll(newNumericFilters);

      final List<List<String>>? finalFacetFilters = facetFilters.isEmpty
          ? null
          : facetFilters.map((f) => [f]).toList();

      final String? finalFilters = numericFilters.isEmpty
          ? null
          : numericFilters.join(' AND ');

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

  Future<List<String>> getFacetValues(String fieldName) async {
    try {
      try {
        final response = await client.search(
          searchMethodParams: algolia_lib.SearchMethodParams(
            requests: [
              algolia_lib.SearchForHits(
                indexName: 'cards',
                query: '',
                facets: [fieldName],
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
          final facetValuesMap = facets[fieldName];

          if (facetValuesMap != null && facetValuesMap is Map) {
            final List<String> values = (facetValuesMap as Map<String, dynamic>)
                .keys
                .where((key) => key != null && key.toString().isNotEmpty)
                .map((key) => key.toString())
                .toList();

            if (values.isNotEmpty) {
              values.sort();
              return values;
            }
          }
        }
      } catch (e) {
        print('[Algolia] Facetten-Laden fehlgeschlagen: $e');
      }

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
                attributesToRetrieve: [fieldName],
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
            final value = hit[fieldName];
            if (value != null && value.toString().isNotEmpty) {
              valuesSet.add(value.toString());
            }
          }
        }

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
      print('[Algolia] Fehler: $e');
      return [];
    }
  }
}
