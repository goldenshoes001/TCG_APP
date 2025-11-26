// lib/class/widgets/ydkexportService.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:algoliasearch/algoliasearch.dart' as algolia_lib;
import 'package:file_picker/file_picker.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class YdkImportService {
  final CardData _cardData = CardData();

  // ✅ OPTIMIZATION 1: Global Cache for card details to prevent multiple Algolia fetches for the same card.
  final Map<String, Map<String, dynamic>> _globalCardCache = {};

  /// ✅ NEW: Export Deck as TXT
  Future<void> exportDeckAsTxt({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    try {
      final txtContent = _createTxtContent(
        deckName: deckName,
        mainDeck: mainDeck,
        extraDeck: extraDeck,
        sideDeck: sideDeck,
      );

      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(txtContent));

      final String safeFileName = deckName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Deck as TXT',
        fileName: '${safeFileName.isEmpty ? 'Deck' : safeFileName}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: fileBytes,
      );

      if (outputPath == null) return;

      print('✅ TXT file successfully exported: $outputPath');
    } catch (e) {
      print('❌ Error during TXT export: $e');
      rethrow;
    }
  }

  /// ✅ OPTIMIZATION 2: Multi-YDK Import (Validation/Parsing now runs PARALLEL)
  Future<List<YdkImportResult>?> importMultipleYdkFiles() async {
    // Allow multiple files
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ydk'],
      withData: false,
      allowMultiple: true, // ✅ IMPORTANT
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    // 1. ✅ PARALLELIZATION: Create a list of Futures for each import operation.
    // Each Future represents the parsing, Algolia fetching, and Banlist validation.
    final List<Future<YdkImportResult?>> importFutures = result.files.map((
      file,
    ) {
      if (file.path == null) return Future.value(null);

      // Start _importSingleYdkFile parallel and catch errors
      return _importSingleYdkFile(file.path!).catchError((e) {
        print('❌ Error importing ${file.name}: $e');
        return null;
      });
    }).toList();

    // 2. ✅ Wait for all parallel import Futures to complete.
    final List<YdkImportResult?> importedDecksWithNulls = await Future.wait(
      importFutures,
    );

    // Filter successful results
    final List<YdkImportResult> importedDecks = importedDecksWithNulls
        .whereType<YdkImportResult>()
        .toList();

    return importedDecks.isEmpty ? null : importedDecks;
  }

  /// ✅ PRIVATE: Imports a single YDK file
  Future<YdkImportResult?> _importSingleYdkFile(String filePath) async {
    final ydkContent = await File(filePath).readAsString();
    final lines = ydkContent.split('\n');
    String deckName = 'Imported Deck';
    List<String> mainIds = [];
    List<String> extraIds = [];
    List<String> sideIds = [];

    List<String>? currentDeck;

    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('#created by')) {
        deckName = line.substring(11).trim().isNotEmpty
            ? line.substring(11).trim()
            : 'Imported Deck';
      } else if (line == '#main') {
        currentDeck = mainIds;
      } else if (line == '#extra') {
        currentDeck = extraIds;
      } else if (line == '!side') {
        currentDeck = sideIds;
      } else if (line.isNotEmpty && RegExp(r'^\d+$').hasMatch(line)) {
        if (currentDeck != null) {
          currentDeck.add(line);
        }
      }
    }

    // ✅ Aggregate and validate against Banlist
    final aggregatedDecks = await _aggregateAndFetchCards(
      mainIds: mainIds,
      extraIds: extraIds,
      sideIds: sideIds,
      validateBannlist: true, // ✅ Enable Banlist check
    );

    return YdkImportResult(
      deckName: deckName,
      mainDeck: aggregatedDecks['main']!,
      extraDeck: aggregatedDecks['extra']!,
      sideDeck: aggregatedDecks['side']!,
    );
  }

  /// ✅ OLD METHOD: Single Import (backward compatibility)
  Future<YdkImportResult?> importYdkFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ydk'],
      withData: false,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return await _importSingleYdkFile(result.files.single.path!);
  }

  /// ✅ OPTIMIZATION 3: Fetches card data + Bannlist Validation (Internal card lookups are now PARALLEL)

  Future<Map<String, List<Map<String, dynamic>>>> _aggregateAndFetchCards({
    required List<String> mainIds,
    required List<String> extraIds,
    required List<String> sideIds,
    bool validateBannlist = false,
  }) async {
    // Get all unique card IDs from the deck parts
    final allIds = {...mainIds, ...extraIds, ...sideIds}.toList();

    // NEU: Setzen Sie die maximale Parallelität (Batch-Größe) auf 8
    // Dies löst die "Connection timed out"-Fehler durch Netzwerk-Überlastung.
    const int maxConcurrency = 8;
    final List<Map<String, dynamic>?> fetchedResults = [];

    // NEU: Führen Sie die Suchen in kontrollierten Batches aus (Throttling)
    for (int i = 0; i < allIds.length; i += maxConcurrency) {
      // Erstellt einen Batch von IDs (maximal 8)
      final currentBatchIds = allIds.sublist(
        i,
        i + maxConcurrency > allIds.length ? allIds.length : i + maxConcurrency,
      );

      // Erstellt die Futures für diesen Batch
      final batchFutures = currentBatchIds
          .map((id) => _searchCardById(id))
          .toList();

      // Wartet, bis dieser Batch von 8 Anfragen abgeschlossen ist
      final results = await Future.wait(batchFutures);

      // Fügt die Ergebnisse zur Gesamtergebnisliste hinzu
      fetchedResults.addAll(results);
    }

    // Create a map of card details for easier aggregation
    final Map<String, Map<String, dynamic>> cardDetailsForDeck = {};
    for (int i = 0; i < allIds.length; i++) {
      final id = allIds[i];
      final details = fetchedResults[i];
      // Check if details were successfully fetched and not null
      if (details != null && details.isNotEmpty) {
        cardDetailsForDeck[id] = details;
      } else {
        print('Warning: Card ID $id not found in Algolia or cache. Skipping.');
      }
    }

    // ✅ Aggregation with Banlist Check
    List<Map<String, dynamic>> aggregate(List<String> ids) {
      final Map<String, int> countMap = {};
      for (var id in ids) {
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> deck = [];
      countMap.forEach((id, count) {
        if (cardDetailsForDeck.containsKey(id)) {
          // Uses the quickly fetched map
          final cardData = Map<String, dynamic>.from(cardDetailsForDeck[id]!);

          if (validateBannlist) {
            // ✅ Check TCG Banlist
            final maxAllowed = _getMaxAllowedCopies(cardData);

            if (maxAllowed == 0) {
              print(
                '⚠️ Card ${cardData['name']} is Forbidden and will be skipped',
              );
              return; // Skip forbidden cards
            }

            if (count > maxAllowed) {
              print(
                '⚠️ Card ${cardData['name']}: $count copies → reduced to $maxAllowed',
              );
              count = maxAllowed;
            }
          }

          cardData['count'] = count;
          deck.add(cardData);
        }
      });
      return deck;
    }

    return {
      'main': aggregate(mainIds),
      'extra': aggregate(extraIds),
      'side': aggregate(sideIds),
    };
  }

  /// ✅ NEW: Determines allowed copies based on TCG Banlist
  int _getMaxAllowedCopies(Map<String, dynamic> card) {
    final banlistInfo = card['banlist_info'];
    if (banlistInfo == null) return 3;

    final tcgBan = banlistInfo['ban_tcg'] as String?;

    if (tcgBan == 'Forbidden') return 0;
    if (tcgBan == 'Limited') return 1;
    if (tcgBan == 'Semi-Limited') return 2;

    return 3;
  }

  /// ✅ OPTIMIZATION 4: Searches for a card by its ID (Algolia) - Now with global cache
  Future<Map<String, dynamic>?> _searchCardById(String cardId) async {
    // 1. ✅ Cache Check (Der größte Performance-Gewinn beim Import vieler Decks)
    if (_globalCardCache.containsKey(cardId)) {
      return _globalCardCache[cardId];
    }
    final clientOptions = algolia_lib.ClientOptions(
      connectTimeout: const Duration(seconds: 120),
    );
    try {
      final client = algolia_lib.SearchClient(
        appId: 'ZFFHWZ011E',
        apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
        // ✅ FIX: Erhöhe das Timeout, um die UnreachableHostsException unter hoher Last zu vermeiden.
        // Von standardmäßig 2 Sekunden auf 30 Sekunden erhöht.
        options: clientOptions,
      );

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              filters: 'id=$cardId',
              hitsPerPage: 1,
            ),
          ],
        ),
      );

      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List || hitsData.isEmpty) {
        return null; // Nichts gefunden
      }

      final Map<String, dynamic> cardDetails = Map<String, dynamic>.from(
        hitsData.first as Map,
      );

      // 2. ✅ Cache Write on success
      _globalCardCache[cardId] = cardDetails; // Speichere im globalen Cache

      return cardDetails;
    } catch (e) {
      print('❌ Error searching for card ID $cardId: $e');
      return null;
    }
  }

  // --- TXT Export Methods (Unchanged) ---

  /// ✅ NEW: Creates TXT Content
  String _createTxtContent({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('# $deckName');
    buffer.writeln('');

    buffer.writeln('## Main Deck (${_getTotalCards(mainDeck)} cards)');
    _addCardsToTxtBuffer(buffer, mainDeck);
    buffer.writeln('');

    buffer.writeln('## Extra Deck (${_getTotalCards(extraDeck)} cards)');
    _addCardsToTxtBuffer(buffer, extraDeck);
    buffer.writeln('');

    buffer.writeln('## Side Deck (${_getTotalCards(sideDeck)} cards)');
    _addCardsToTxtBuffer(buffer, sideDeck);

    return buffer.toString();
  }

  void _addCardsToTxtBuffer(
    StringBuffer buffer,
    List<Map<String, dynamic>> deck,
  ) {
    for (var card in deck) {
      final count = card['count'] as int? ?? 0;
      final name = card['name'] as String? ?? 'Unknown';
      buffer.writeln('$count x $name');
    }
  }

  int _getTotalCards(List<Map<String, dynamic>> deck) {
    return deck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
  }

  // --- YDK Export Methods (Unchanged) ---

  /// Exports a deck as a YDK file
  Future<void> exportYdkFile({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    try {
      final ydkContent = _createYdkContent(
        deckName: deckName,
        mainDeck: mainDeck,
        extraDeck: extraDeck,
        sideDeck: sideDeck,
      );

      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(ydkContent));

      final rawSafeFileName = deckName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      final String safeFileName = rawSafeFileName.isEmpty
          ? 'Unnamed_Deck'
          : rawSafeFileName;

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save YDK File',
        fileName: '$safeFileName.ydk',
        type: FileType.custom,
        allowedExtensions: ['ydk'],
        bytes: fileBytes,
      );

      if (outputPath == null) return;

      print('✅ YDK file successfully exported: $outputPath');
    } catch (e) {
      print('❌ Error during YDK export: $e');
      rethrow;
    }
  }

  String _createYdkContent({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('#created by $deckName');

    buffer.writeln('#main');
    _addCardsToBuffer(buffer, mainDeck);

    buffer.writeln('#extra');
    _addCardsToBuffer(buffer, extraDeck);

    buffer.writeln('!side');
    _addCardsToBuffer(buffer, sideDeck);

    return buffer.toString();
  }

  void _addCardsToBuffer(StringBuffer buffer, List<Map<String, dynamic>> deck) {
    for (var card in deck) {
      final cardId = card['id']?.toString() ?? '0';
      final count = card['count'] as int? ?? 0;
      for (int i = 0; i < count; i++) {
        buffer.writeln(cardId);
      }
    }
  }
}

/// Result of a YDK import
class YdkImportResult {
  final String deckName;
  final List<Map<String, dynamic>> mainDeck;
  final List<Map<String, dynamic>> extraDeck;
  final List<Map<String, dynamic>> sideDeck;

  num get totalCards =>
      mainDeck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0)) +
      extraDeck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0)) +
      sideDeck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));

  YdkImportResult({
    required this.deckName,
    required this.mainDeck,
    required this.extraDeck,
    required this.sideDeck,
  });
}
