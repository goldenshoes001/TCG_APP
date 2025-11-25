// lib/class/widgets/ydkexportService.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:algoliasearch/algoliasearch.dart' as algolia_lib;
import 'package:file_picker/file_picker.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class YdkImportService {
  final CardData _cardData = CardData();

  /// Exports a deck as a YDK file
  Future<void> exportYdkFile({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) async {
    try {
      // Create YDK string content
      final ydkContent = _createYdkContent(
        deckName: deckName,
        mainDeck: mainDeck,
        extraDeck: extraDeck,
        sideDeck: sideDeck,
      );

      // Convert YDK string to bytes (Fix for "Bytes are required")
      final Uint8List fileBytes = Uint8List.fromList(utf8.encode(ydkContent));

      // Clean file name (remove special characters)
      final rawSafeFileName = deckName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      // Fallback logic: Ensure the filename is not empty (Fix for "Missing file name")
      final String safeFileName = rawSafeFileName.isEmpty
          ? 'Unnamed_Deck' // Fallback name if deckName is empty or only invalid characters
          : rawSafeFileName;

      // Let the user choose the save location and save the file
      // On Android/iOS, the file is saved directly by providing the 'bytes' parameter.
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save YDK File',
        fileName: '$safeFileName.ydk',
        type: FileType.custom,
        allowedExtensions: ['ydk'],
        bytes: fileBytes, // <<< IMPORTANT: Pass bytes for mobile platforms
      );

      if (outputPath == null) {
        // User cancelled
        return;
      }

      // Removed manual file writing (file.writeAsBytes), as it's handled by saveFile when 'bytes' is provided.

      print('✅ YDK file successfully exported: $outputPath');
    } catch (e) {
      print('❌ Error during YDK export: $e');
      // Rethrow error to be handled by the UI (e.g., SnackBar)
      rethrow;
    }
  }

  /// Creates the YDK content from the deck lists
  String _createYdkContent({
    required String deckName,
    required List<Map<String, dynamic>> mainDeck,
    required List<Map<String, dynamic>> extraDeck,
    required List<Map<String, dynamic>> sideDeck,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('#created by $deckName');

    // Main Deck
    buffer.writeln('#main');
    _addCardsToBuffer(buffer, mainDeck);

    // Extra Deck
    buffer.writeln('#extra');
    _addCardsToBuffer(buffer, extraDeck);

    // Side Deck
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

  /// Imports a YDK file and returns the card information
  Future<YdkImportResult?> importYdkFile() async {
    // ... (Import logic maintained)

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ydk'],
      withData: false,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final filePath = result.files.single.path!;
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

    // Aggregate and convert IDs to card data
    final aggregatedDecks = await _aggregateAndFetchCards(
      mainIds: mainIds,
      extraIds: extraIds,
      sideIds: sideIds,
    );

    return YdkImportResult(
      deckName: deckName,
      mainDeck: aggregatedDecks['main']!,
      extraDeck: aggregatedDecks['extra']!,
      sideDeck: aggregatedDecks['side']!,
    );
  }

  /// Fetches card data for all IDs and aggregates them
  Future<Map<String, List<Map<String, dynamic>>>> _aggregateAndFetchCards({
    required List<String> mainIds,
    required List<String> extraIds,
    required List<String> sideIds,
  }) async {
    final allIds = {...mainIds, ...extraIds, ...sideIds}.toList();
    final Map<String, Map<String, dynamic>> cardCache = {};

    // Fetch card details in batches (Algolia search)
    for (var id in allIds) {
      final cardDetails = await _searchCardById(id);
      if (cardDetails.isNotEmpty) {
        cardCache[id] = cardDetails.first;
      } else {
        print('Warning: Card ID $id not found in Algolia.');
      }
    }

    // Aggregation function
    List<Map<String, dynamic>> aggregate(List<String> ids) {
      final Map<String, int> countMap = {};
      for (var id in ids) {
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> deck = [];
      countMap.forEach((id, count) {
        if (cardCache.containsKey(id)) {
          final cardData = Map<String, dynamic>.from(cardCache[id]!);
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

  /// Searches for a card by its ID (Algolia)
  Future<List<Map<String, dynamic>>> _searchCardById(String cardId) async {
    try {
      // Algolia with filter on 'id' field
      final client = algolia_lib.SearchClient(
        appId: 'ZFFHWZ011E',
        apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
      );

      final response = await client.search(
        searchMethodParams: algolia_lib.SearchMethodParams(
          requests: [
            algolia_lib.SearchForHits(
              indexName: 'cards',
              filters: 'id=$cardId', // ⭐ DIRECT ID SEARCH
              hitsPerPage: 1,
            ),
          ],
        ),
      );

      final dynamic hitsData = (response.results.first as Map)['hits'];

      if (hitsData == null || hitsData is! List) {
        return [];
      }

      final List<dynamic> hits = hitsData;
      return hits.map((hit) => Map<String, dynamic>.from(hit as Map)).toList();
    } catch (e) {
      print('❌ Error searching for card ID $cardId: $e');
      return [];
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
