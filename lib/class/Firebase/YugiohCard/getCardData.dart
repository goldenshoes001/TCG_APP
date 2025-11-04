// getCardData.dart - OPTIMIERT, BEREINIGT UND MIT WIEDERHERGESTELLTEM getCorrectImgPath

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

  // Image URL Cache
  static final Map<String, String> _imageUrlCache = {};
  static final Map<String, Future<String>> _loadingQueue = {};

  // --- IMAGE METHODEN ---

  /// Ruft die Download-URL von Firebase Storage ab.
  /// Nutzt LoadingQueue, um Redundanz zu verhindern.
  Future<String> getImgPath(String gsPath) async {
    // Vermeide unnötige Neuladung, wenn der Pfad bereits im Cache des Data-Layers ist
    if (_imageUrlCache.containsKey(gsPath)) {
      return _imageUrlCache[gsPath]!;
    }

    // Wenn bereits in der Warteschlange, auf das Ergebnis warten
    if (_loadingQueue.containsKey(gsPath)) {
      return await _loadingQueue[gsPath]!;
    }

    final Future<String> loadFuture = _loadImageUrl(gsPath);
    _loadingQueue[gsPath] = loadFuture;

    try {
      final String url = await loadFuture;
      if (url.isNotEmpty) {
        // Caching im Data-Layer
        _imageUrlCache[gsPath] = url;
      }
      return url;
    } catch (_) {
      return '';
    } finally {
      _loadingQueue.remove(gsPath);
    }
  }

  Future<String> _loadImageUrl(String gsPath) async {
    // Prüft, ob es sich überhaupt um einen gs:// Pfad handelt.
    if (!gsPath.startsWith('gs://')) {
      return '';
    }

    try {
      final Uri uri = Uri.parse(gsPath);
      // WICHTIG: Dekodiere den Pfad, um %20 in Leerzeichen umzuwandeln
      String path = Uri.decodeComponent(uri.path);

      // Entferne führenden Slash
      if (path.startsWith('/')) {
        path = path.substring(1);
      }

      final Reference gsReference = storage.ref(path);

      // getDownloadURL ist effizient, da es implizit die Existenz prüft.
      final String downloadUrl = await gsReference.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (_) {
      // Fehler im Zusammenhang mit Firebase (z.B. object-not-found)
      return '';
    } catch (_) {
      // Allgemeine Fehler
      return '';
    }
  }

  /// Lädt mehrere URLs parallel (Batch-Loading)
  Future<Map<String, String>> batchLoadImages(List<String> gsPaths) async {
    final Map<String, String> results = {};

    final List<String> uncached = gsPaths
        .where((p) => !_imageUrlCache.containsKey(p))
        .toList();

    if (uncached.isEmpty) {
      for (var path in gsPaths) {
        results[path] = _imageUrlCache[path]!;
      }
      return results;
    }

    // Führe maximal 10 Anfragen gleichzeitig aus (zur Ressourcenschonung)
    for (int i = 0; i < uncached.length; i += 10) {
      final List<String> batch = uncached.skip(i).take(10).toList();
      final List<Future<String>> futures = batch
          .map((path) => getImgPath(path))
          .toList();
      final List<String> urls = await Future.wait(futures);

      for (int j = 0; j < batch.length; j++) {
        results[batch[j]] = urls[j];
      }
    }

    // Füge gecachte Ergebnisse hinzu
    for (var path in gsPaths) {
      if (_imageUrlCache.containsKey(path)) {
        results[path] = _imageUrlCache[path]!;
      }
    }

    return results;
  }

  /// Preload-Funktion für die ersten Bilder einer Kartenliste.
  Future<void> preloadCardImages(
    List<Map<String, dynamic>> cards, {
    int maxCards = 50,
  }) async {
    final List<String> imagePaths = <String>[];

    for (var card in cards.take(maxCards)) {
      if (card["card_images"] != null &&
          card["card_images"] is List &&
          (card["card_images"] as List).isNotEmpty) {
        final firstImage = card["card_images"][0];
        if (firstImage is Map<String, dynamic>) {
          final imageUrl = firstImage["image_url"];
          final imageUrlCropped = firstImage["image_url_cropped"];

          if (imageUrl != null &&
              imageUrl.toString().isNotEmpty &&
              imageUrl.toString().startsWith('gs://')) {
            imagePaths.add(imageUrl.toString());
          }
          if (imageUrlCropped != null &&
              imageUrlCropped.toString().isNotEmpty &&
              imageUrlCropped.toString().startsWith('gs://')) {
            imagePaths.add(imageUrlCropped.toString());
          }
        }
      }
    }

    if (imagePaths.isNotEmpty) {
      await batchLoadImages(imagePaths);
    }
  }

  void clearImageCache() {
    _imageUrlCache.clear();
  }

  int getImageCacheSize() => _imageUrlCache.length;

  /// **WIEDERHERGESTELLT & OPTIMIERT:** Findet den korrekten Bildpfad.
  /// Diese Methode nimmt eine Liste von URLs (typischerweise IDs) entgegen,
  /// konstruiert den erwarteten Storage-Pfad und versucht, die Download-URL zu erhalten.
  /// **KORRIGIERT:** Findet den korrekten Bildpfad.
  /// Diese Methode nimmt eine Liste von URLs entgegen (bereits vollständige gs:// Pfade)
  /// und versucht, die Download-URL zu erhalten.
  Future<String> getCorrectImgPath(List<String> imageUrls) async {
    for (var imageUrl in imageUrls) {
      if (imageUrl.isEmpty) continue;

      // Die imageUrls sind bereits vollständige gs:// Pfade
      // Verwende sie direkt mit getImgPath
      final String downloadUrl = await getImgPath(imageUrl);

      if (downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
    }

    // Fallback: Wenn alle Pfade fehlschlagen, gib einen leeren String zurück
    return '';
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

  // --- HAUPTSUCHE MIT EXAKTER TYP-SUCHE UND AND-LOGIK ---

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
    final List<List<String>> facetFilters = [];
    final List<String> numericFilters = [];

    // EXAKTE TYP-SUCHE MIT AND-LOGIK
    if (type != null && type.isNotEmpty) {
      facetFilters.add(['type:$type']);
    }

    // Weitere Facet Filters (alle mit AND-Logik verknüpft)
    if (race != null && race.isNotEmpty) {
      facetFilters.add(['race:$race']);
    }
    if (attribute != null && attribute.isNotEmpty) {
      facetFilters.add(['attribute:$attribute']);
    }
    if (archetype != null && archetype.isNotEmpty) {
      facetFilters.add(['archetype:$archetype']);
    }
    if (banlistTCG != null && banlistTCG.isNotEmpty) {
      facetFilters.add(['banlist_info.ban_tcg:$banlistTCG']);
    }
    if (banlistOCG != null && banlistOCG.isNotEmpty) {
      facetFilters.add(['banlist_info.ban_ocg:$banlistOCG']);
    }

    // Numeric Filters (ebenfalls mit AND verknüpft)
    if (level != null) {
      numericFilters.add(
        'level${_convertOperator(levelOperator ?? '=')}$level',
      );
    }
    if (linkRating != null) {
      numericFilters.add(
        'linkval${_convertOperator(linkRatingOperator ?? '=')}$linkRating',
      );
    }
    if (scale != null) {
      numericFilters.add(
        'scale${_convertOperator(scaleOperator ?? '=')}$scale',
      );
    }
    if (atk != null && atk.isNotEmpty && atk != '?') {
      numericFilters.add('atk$atk');
    }
    if (def != null && def.isNotEmpty && def != '?') {
      numericFilters.add('def$def');
    }

    return await _searchAlgoliaWithFilters(facetFilters, numericFilters);
  }

  // --- ALGOLIA SUCHE ---

  Future<List<Map<String, dynamic>>> _searchAlgoliaWithFilters(
    List<List<String>> facetFilters,
    List<String> numericFilters,
  ) async {
    try {
      final List<List<String>>? finalFacetFilters = facetFilters.isEmpty
          ? null
          : facetFilters;

      final String? finalFilters = numericFilters.isEmpty
          ? null
          : numericFilters.join(' AND ');

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: '',
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
    } catch (_) {
      return [];
    }
  }

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
              removeWordsIfNoResults: algolia_lib.RemoveWordsIfNoResults.none,
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
    } catch (_) {
      return [];
    }
  }
  // --- WEITERE METHODEN ---

  Future<List<Map<String, dynamic>>> getallChards() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTCGBannedCards() async {
    const String filter =
        'banlist_info.ban_tcg:Forbidden OR banlist_info.ban_tcg:Limited OR banlist_info.ban_tcg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

  Future<List<Map<String, dynamic>>> getOCGBannedCards() async {
    const String filter =
        'banlist_info.ban_ocg:Forbidden OR banlist_info.ban_ocg:Limited OR banlist_info.ban_ocg:Semi-Limited';
    return _searchAlgolia(null, filter);
  }

  Future<Map<String, List<dynamic>>> sortTCGBannCards() async {
    final List<Map<String, dynamic>> liste = await getTCGBannedCards();
    final List<dynamic> banned = [];
    final List<dynamic> semiLimited = [];
    final List<dynamic> limited = [];

    final Map<String, List<dynamic>> sortedList = {};

    for (var element in liste) {
      if (element["banlist_info"] is Map) {
        final String? banStatus = element["banlist_info"]["ban_tcg"] as String?;

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
    final List<Map<String, dynamic>> liste = await getOCGBannedCards();
    final List<dynamic> banned = [];
    final List<dynamic> semiLimited = [];
    final List<dynamic> limited = [];

    final Map<String, List<dynamic>> sortedList = {};

    for (var element in liste) {
      if (element["banlist_info"] is Map) {
        final String? banStatus = element["banlist_info"]["ban_ocg"] as String?;

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

    final normalizedSearch = suchfeld.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedSearch.isEmpty) return [];

    final searchPhrase = normalizedSearch.toLowerCase();

    try {
      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: normalizedSearch,
              removeWordsIfNoResults: algolia_lib.RemoveWordsIfNoResults.none,
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

      // FILTER: Behalte nur Karten, bei denen die EXAKTE PHRASE im Namen ODER Archetype ODER Kartentext vorkommt
      final List<Map<String, dynamic>> filteredCards = hits
          .map((hit) => Map<String, dynamic>.from(hit as Map))
          .where((card) {
            final name = (card['name'] as String? ?? '').toLowerCase();
            final desc = (card['desc'] as String? ?? '').toLowerCase();
            final archetype = (card['archetype'] as String? ?? '')
                .toLowerCase();

            // Prüfe ob die exakte Phrase in einem der Felder vorkommt
            return name.contains(searchPhrase) ||
                archetype.contains(searchPhrase) ||
                desc.contains(searchPhrase);
          })
          .toList();

      // Einfach alphabetisch sortieren
      filteredCards.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );

      return filteredCards;
    } catch (_) {
      return [];
    }
  }

  Future<void> updateAlgoliaWithImages() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    final algolia_lib.SearchClient writeClient = algolia_lib.SearchClient(
      appId: 'ZFFHWZ011E',
      apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
    );

    try {
      const int batchSize = 500;
      DocumentSnapshot? lastDoc;

      while (true) {
        Query query = db.collection('cards').limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final QuerySnapshot snapshot = await query.get();

        if (snapshot.docs.isEmpty) {
          break;
        }

        final List<Map<String, dynamic>> recordsToUpdate = [];

        for (var doc in snapshot.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          final Map<String, dynamic> record = {
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

        lastDoc = snapshot.docs.last;

        await Future.delayed(const Duration(milliseconds: 500));
      }

      writeClient.dispose();
    } catch (_) {
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
          final dynamic facetValuesMap = facets[fieldName];

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
      } catch (_) {
        // Fehlerbehandlung ohne Print
      }

      final Set<String> valuesSet = {};
      int page = 0;
      const int hitsPerPage = 1000;
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
            final dynamic value = hit[fieldName];
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
    } catch (_) {
      return [];
    }
  }
}
