// getCardData.dart - OPTIMIERT MIT QUERY-CACHING

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

  // ===== NEUE QUERY-CACHES =====
  // Cache für Suchergebnisse (Query -> Ergebnisse)
  static final Map<String, List<Map<String, dynamic>>> _searchResultsCache = {};

  // Cache für Filter-Suchen (FilterKey -> Ergebnisse)
  static final Map<String, List<Map<String, dynamic>>> _filterResultsCache = {};

  // Cache für Facet Values (FieldName -> Values)
  static final Map<String, List<String>> _facetValuesCache = {};

  // Cache für Bannlist-Daten
  static Map<String, List<dynamic>>? _tcgBannlistCache;
  static Map<String, List<dynamic>>? _ocgBannlistCache;

  // Timestamps für Cache-Invalidierung (optional)
  static DateTime? _lastCacheClear;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  // --- CACHE MANAGEMENT ---

  /// Löscht alle Caches (z.B. bei App-Start oder nach Timeout)
  void clearAllCaches() {
    _imageUrlCache.clear();
    _searchResultsCache.clear();
    _filterResultsCache.clear();
    _facetValuesCache.clear();
    _tcgBannlistCache = null;
    _ocgBannlistCache = null;
    _lastCacheClear = DateTime.now();
  }

  /// Prüft, ob Cache noch gültig ist
  bool _isCacheValid() {
    if (_lastCacheClear == null) return true;
    return DateTime.now().difference(_lastCacheClear!) < _cacheValidDuration;
  }

  // --- IMAGE METHODEN (UNVERÄNDERT) ---

  Future<String> getImgPath(String gsPath) async {
    if (_imageUrlCache.containsKey(gsPath)) {
      return _imageUrlCache[gsPath]!;
    }

    if (_loadingQueue.containsKey(gsPath)) {
      return await _loadingQueue[gsPath]!;
    }

    final Future<String> loadFuture = _loadImageUrl(gsPath);
    _loadingQueue[gsPath] = loadFuture;

    try {
      final String url = await loadFuture;
      if (url.isNotEmpty) {
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
    if (!gsPath.startsWith('gs://')) {
      return '';
    }

    try {
      final Uri uri = Uri.parse(gsPath);
      String path = Uri.decodeComponent(uri.path); // NUR EINMAL dekodieren!

      if (path.startsWith('/')) {
        path = path.substring(1);
      }

      // ENTFERNE diese Zeile:
      // path = Uri.decodeComponent(path); // ❌ DOPPELTE DEKODIERUNG!

      print('🔍 Trying to load: $path');

      final Reference gsReference = storage.ref(path);
      final String downloadUrl = await gsReference.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('❌ Firebase Storage Error: ${e.code} - ${e.message}');
      print('❌ Path war: $gsPath');
      return '';
    } catch (e) {
      print('❌ Fehler: $e');
      return '';
    }
  }

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

    for (var path in gsPaths) {
      if (_imageUrlCache.containsKey(path)) {
        results[path] = _imageUrlCache[path]!;
      }
    }

    return results;
  }

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

  Future<String> getCorrectImgPath(List<String> imageUrls) async {
    for (var imageUrl in imageUrls) {
      if (imageUrl.isEmpty) continue;

      final String downloadUrl = await getImgPath(imageUrl);
      print(downloadUrl);

      if (downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
    }

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

  /// Erstellt einen eindeutigen Cache-Key für Filter-Suchen
  String _createFilterCacheKey({
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
  }) {
    return 'filter_${type ?? ''}_${race ?? ''}_${attribute ?? ''}_'
        '${archetype ?? ''}_${level ?? ''}_${levelOperator ?? ''}_'
        '${linkRating ?? ''}_${linkRatingOperator ?? ''}_'
        '${scale ?? ''}_${scaleOperator ?? ''}_'
        '${atk ?? ''}_${def ?? ''}_${banlistTCG ?? ''}_${banlistOCG ?? ''}';
  }

  // --- HAUPTSUCHE MIT CACHING ---

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
    // Prüfe Cache
    if (_isCacheValid()) {
      final cacheKey = _createFilterCacheKey(
        type: type,
        race: race,
        attribute: attribute,
        archetype: archetype,
        level: level,
        levelOperator: levelOperator,
        linkRating: linkRating,
        linkRatingOperator: linkRatingOperator,
        scale: scale,
        scaleOperator: scaleOperator,
        atk: atk,
        def: def,
        banlistTCG: banlistTCG,
        banlistOCG: banlistOCG,
      );

      if (_filterResultsCache.containsKey(cacheKey)) {
        print('Cache HIT für Filter-Suche');
        return _filterResultsCache[cacheKey]!;
      }
    }

    final List<List<String>> facetFilters = [];
    final List<String> numericFilters = [];

    if (type != null && type.isNotEmpty) {
      facetFilters.add(['type:$type']);
    }

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

    final results = await _searchAlgoliaWithFilters(
      facetFilters,
      numericFilters,
    );

    // Cache speichern
    final cacheKey = _createFilterCacheKey(
      type: type,
      race: race,
      attribute: attribute,
      archetype: archetype,
      level: level,
      levelOperator: levelOperator,
      linkRating: linkRating,
      linkRatingOperator: linkRatingOperator,
      scale: scale,
      scaleOperator: scaleOperator,
      atk: atk,
      def: def,
      banlistTCG: banlistTCG,
      banlistOCG: banlistOCG,
    );
    _filterResultsCache[cacheKey] = results;

    return results;
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

      final List<dynamic> hits = hitsData;

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

      final List<dynamic> hits = hitsData;

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

  // --- WEITERE METHODEN MIT CACHING ---

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
    // Cache-Check
    if (_isCacheValid() && _tcgBannlistCache != null) {
      print('Cache HIT für TCG Bannlist');
      return _tcgBannlistCache!;
    }

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

    // Cache speichern
    _tcgBannlistCache = sortedList;

    return sortedList;
  }

  Future<Map<String, List<dynamic>>> sortOCGBannCards() async {
    // Cache-Check
    if (_isCacheValid() && _ocgBannlistCache != null) {
      print('Cache HIT für OCG Bannlist');
      return _ocgBannlistCache!;
    }

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

    // Cache speichern
    _ocgBannlistCache = sortedList;

    return sortedList;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCardsFromBannlist() async {
    return getTCGBannedCards();
  }

  // Version 1: NUR exakte Phrasen (keine Schreibfehler-Toleranz)
  // Groß-/Kleinschreibung wird ignoriert
  // Ersetze ergebniseAnzeigen in getCardData.dart:

  Future<List<Map<String, dynamic>>> ergebniseAnzeigen(String suchfeld) async {
    if (suchfeld.isEmpty) return [];

    final normalizedSearch = suchfeld.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalizedSearch.isEmpty) return [];

    // Cache-Check für Textsuche
    if (_isCacheValid() && _searchResultsCache.containsKey(normalizedSearch)) {
      print('Cache HIT für Suche: $normalizedSearch');
      return _searchResultsCache[normalizedSearch]!;
    }

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
              // WICHTIG: Typo-Toleranz DEAKTIVIEREN für exakte Suche
              typoTolerance: algolia_lib.TypoToleranceEnum.false_,
            ),
          ],
        ),
      );

      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List) {
        return [];
      }

      final List<dynamic> hits = hitsData;

      // Filtere NUR nach exakter Phrase (mit Bindestrich-Toleranz)
      final List<Map<String, dynamic>> filteredCards = hits
          .map((hit) => Map<String, dynamic>.from(hit as Map))
          .where((card) {
            final name = (card['name'] as String? ?? '').toLowerCase();
            final desc = (card['desc'] as String? ?? '').toLowerCase();
            final archetype = (card['archetype'] as String? ?? '')
                .toLowerCase();

            // Normalisiere beide Seiten: Bindestriche → Leerzeichen
            final normalizedName = name
                .replaceAll('-', ' ')
                .replaceAll(RegExp(r'\s+'), ' ');
            final normalizedDesc = desc
                .replaceAll('-', ' ')
                .replaceAll(RegExp(r'\s+'), ' ');
            final normalizedArchetype = archetype
                .replaceAll('-', ' ')
                .replaceAll(RegExp(r'\s+'), ' ');
            final normalizedSearchPhrase = searchPhrase
                .replaceAll('-', ' ')
                .replaceAll(RegExp(r'\s+'), ' ');

            // Prüfe ob die EXAKTE Phrase vorkommt (mit und ohne Bindestrich)
            return name.contains(searchPhrase) ||
                normalizedName.contains(normalizedSearchPhrase) ||
                archetype.contains(searchPhrase) ||
                normalizedArchetype.contains(normalizedSearchPhrase) ||
                desc.contains(searchPhrase) ||
                normalizedDesc.contains(normalizedSearchPhrase);
          })
          .toList();

      filteredCards.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );

      // Cache speichern
      _searchResultsCache[normalizedSearch] = filteredCards;

      return filteredCards;
    } catch (e) {
      print('Fehler bei Algolia-Suche: $e');
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

  /// OPTIMIERT: Lädt Facet-Werte mit Caching
  Future<List<String>> getFacetValues(String fieldName) async {
    // Cache-Check
    if (_isCacheValid() && _facetValuesCache.containsKey(fieldName)) {
      print('Cache HIT für Facets: $fieldName');
      return _facetValuesCache[fieldName]!;
    }

    try {
      // Versuche zuerst, Facets direkt zu laden (effizienteste Methode)
      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              query: '',
              facets: [fieldName],
              hitsPerPage: 0, // Keine Hits, nur Facets
              maxValuesPerFacet: 100000,
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
              .where((key) => key.toString().isNotEmpty)
              .map((key) => key.toString())
              .toList();

          if (values.isNotEmpty) {
            values.sort();
            // Cache speichern
            _facetValuesCache[fieldName] = values;
            return values;
          }
        }
      }

      // Fallback nur wenn nötig (sollte nicht passieren)
      return [];
    } catch (_) {
      return [];
    }
  }
}
