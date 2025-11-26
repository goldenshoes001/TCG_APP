// lib/class/widgets/ydkexportService.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:algoliasearch/algoliasearch.dart' as algolia_lib;
import 'package:file_picker/file_picker.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class YdkImportService {
  final CardData _cardData = CardData();

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

  /// ✅ NEU: Multi-YDK Import
  Future<List<YdkImportResult>?> importMultipleYdkFiles() async {
    // Erlaube mehrere Dateien
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ydk'],
      withData: false,
      allowMultiple: true, // ✅ WICHTIG
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final List<YdkImportResult> importedDecks = [];

    for (var file in result.files) {
      if (file.path == null) continue;

      try {
        final ydkResult = await _importSingleYdkFile(file.path!);
        if (ydkResult != null) {
          importedDecks.add(ydkResult);
        }
      } catch (e) {
        print('❌ Fehler beim Import von ${file.name}: $e');
      }
    }

    return importedDecks.isEmpty ? null : importedDecks;
  }

  /// ✅ PRIVATE: Importiert eine einzelne YDK-Datei
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

    // ✅ Aggregiere und validiere gegen Bannlist
    final aggregatedDecks = await _aggregateAndFetchCards(
      mainIds: mainIds,
      extraIds: extraIds,
      sideIds: sideIds,
      validateBannlist: true, // ✅ Bannlist-Check aktivieren
    );

    return YdkImportResult(
      deckName: deckName,
      mainDeck: aggregatedDecks['main']!,
      extraDeck: aggregatedDecks['extra']!,
      sideDeck: aggregatedDecks['side']!,
    );
  }

  /// ✅ ALTE METHODE: Single Import (backward compatibility)
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

  /// ✅ UPDATED: Fetches card data + Bannlist Validation
  Future<Map<String, List<Map<String, dynamic>>>> _aggregateAndFetchCards({
    required List<String> mainIds,
    required List<String> extraIds,
    required List<String> sideIds,
    bool validateBannlist = false,
  }) async {
    final allIds = {...mainIds, ...extraIds, ...sideIds}.toList();
    final Map<String, Map<String, dynamic>> cardCache = {};

    // Fetch card details
    for (var id in allIds) {
      final cardDetails = await _searchCardById(id);
      if (cardDetails.isNotEmpty) {
        cardCache[id] = cardDetails.first;
      } else {
        print('Warning: Card ID $id not found in Algolia.');
      }
    }

    // ✅ Aggregation mit Bannlist-Check
    List<Map<String, dynamic>> aggregate(List<String> ids) {
      final Map<String, int> countMap = {};
      for (var id in ids) {
        countMap[id] = (countMap[id] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> deck = [];
      countMap.forEach((id, count) {
        if (cardCache.containsKey(id)) {
          final cardData = Map<String, dynamic>.from(cardCache[id]!);

          if (validateBannlist) {
            // ✅ Prüfe TCG Bannlist
            final maxAllowed = _getMaxAllowedCopies(cardData);

            if (maxAllowed == 0) {
              print(
                '⚠️ Karte ${cardData['name']} ist verboten und wird übersprungen',
              );
              return; // Skip verbotene Karten
            }

            if (count > maxAllowed) {
              print(
                '⚠️ Karte ${cardData['name']}: $count Kopien → auf $maxAllowed reduziert',
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

  /// ✅ NEU: Ermittelt erlaubte Anzahl basierend auf TCG Bannlist
  int _getMaxAllowedCopies(Map<String, dynamic> card) {
    final banlistInfo = card['banlist_info'];
    if (banlistInfo == null) return 3;

    final tcgBan = banlistInfo['ban_tcg'] as String?;

    if (tcgBan == 'Forbidden') return 0;
    if (tcgBan == 'Limited') return 1;
    if (tcgBan == 'Semi-Limited') return 2;

    return 3;
  }

  /// Searches for a card by its ID (Algolia)
  Future<List<Map<String, dynamic>>> _searchCardById(String cardId) async {
    try {
      final client = algolia_lib.SearchClient(
        appId: 'ZFFHWZ011E',
        apiKey: 'bbcc7bed24e11232cbfd76ce9017b629',
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

  /// ✅ NEU: TXT Export (Alternative zu YDK)

  /// ✅ NEU: Erstellt TXT-Inhalt
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

  /// Exports a deck as a YDK file (UNCHANGED)
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
