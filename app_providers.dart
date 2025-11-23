// TODO Implement this library.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/Firebase/interfaces/FirebaseAuthRepository.dart';
import 'package:tcg_app/class/Firebase/user/user.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/sharedPreference.dart';

// Füge diesen Provider hinzu:
final combinedSearchResultsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final query = ref.watch(cardSearchQueryProvider);
      final filterState = ref.watch(filterProvider);
      final cardData = ref.watch(cardDataProvider);

      print('🔄 Combined Search triggered:');
      print('   Query: "$query"');
      print('   Filter: $filterState');

      // Prüfe ob überhaupt eine Suche aktiv ist
      final hasQuery = query.isNotEmpty;
      final hasFilters =
          filterState.selectedType != null ||
          filterState.selectedRace != null ||
          filterState.selectedAttribute != null ||
          filterState.selectedArchetype != null ||
          filterState.selectedLevel != null ||
          filterState.atkValue.isNotEmpty ||
          filterState.defValue.isNotEmpty ||
          filterState.selectedScale != null ||
          filterState.selectedLinkRating != null ||
          filterState.selectedBanlistTCG != null ||
          filterState.selectedBanlistOCG != null;

      // Wenn weder Suchwort noch Filter gesetzt sind, leere Liste zurückgeben
      if (!hasQuery && !hasFilters) {
        return [];
      }

      // ✅ NEUE LOGIK: Teile Suchbegriff in einzelne Wörter
      final searchWords = hasQuery
          ? query.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList()
          : <String>[];

      print(
        '🔍 Kombinierte Suche - ALLE Wörter müssen vorkommen: $searchWords',
      );

      // Verwende die kombinierte Suchmethode
      int? levelValue;
      String? levelOperatorValue;
      int? scaleValue;
      String? scaleOperatorValue;
      int? linkRatingValue;
      String? linkRatingOperatorValue;
      String? atkFilter;
      String? defFilter;

      if (filterState.selectedLevel != null) {
        levelValue = int.tryParse(filterState.selectedLevel!);
        levelOperatorValue = filterState.levelOperator;
      }
      if (filterState.selectedScale != null) {
        scaleValue = int.tryParse(filterState.selectedScale!);
        scaleOperatorValue = filterState.scaleOperator;
      }
      if (filterState.selectedLinkRating != null) {
        linkRatingValue = int.tryParse(filterState.selectedLinkRating!);
        linkRatingOperatorValue = filterState.linkRatingOperator;
      }
      if (filterState.atkValue.isNotEmpty) {
        final atkOp = filterState.atkOperator == 'min'
            ? '>='
            : filterState.atkOperator == 'max'
            ? '<='
            : '=';
        atkFilter = '$atkOp${filterState.atkValue}';
      }
      if (filterState.defValue.isNotEmpty) {
        final defOp = filterState.defOperator == 'min'
            ? '>='
            : filterState.defOperator == 'max'
            ? '<='
            : '=';
        defFilter = '$defOp${filterState.defValue}';
      }

      final results = await cardData.searchWithQueryAndFilters(
        query: hasQuery ? query : null,
        type: filterState.selectedType,
        race: filterState.selectedRace,
        attribute: filterState.selectedAttribute,
        archetype: filterState.selectedArchetype,
        level: levelValue,
        levelOperator: levelOperatorValue,
        linkRating: linkRatingValue,
        linkRatingOperator: linkRatingOperatorValue,
        scale: scaleValue,
        scaleOperator: scaleOperatorValue,
        atk: atkFilter,
        def: defFilter,
        banlistTCG: filterState.selectedBanlistTCG,
        banlistOCG: filterState.selectedBanlistOCG,
      );

      print('📊 Vor Wort-Filterung: ${results.length} Karten');

      // ✅ NEUE FILTERLOGIK: Filtere nach ALLEN Wörtern
      List<Map<String, dynamic>> filteredResults = results;

      if (searchWords.isNotEmpty) {
        // Erstelle die Suchphrase
        final searchPhrase = searchWords.join(' ');

        filteredResults = results.where((card) {
          final name = (card['name'] as String? ?? '').toLowerCase();
          final desc = (card['desc'] as String? ?? '').toLowerCase();
          final archetype = (card['archetype'] as String? ?? '').toLowerCase();

          final normalizedName = name
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          final normalizedDesc = desc
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          final normalizedArchetype = archetype
              .replaceAll('-', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');

          // ✅ Suche überall nach der kompletten Phrase
          bool phraseInName =
              name.contains(searchPhrase) ||
              normalizedName.contains(searchPhrase);

          bool phraseInArchetype =
              archetype.contains(searchPhrase) ||
              normalizedArchetype.contains(searchPhrase);

          bool phraseInDesc =
              desc.contains(searchPhrase) ||
              normalizedDesc.contains(searchPhrase);

          final matches = phraseInName || phraseInArchetype || phraseInDesc;

          // Debug-Ausgabe
          if (name.contains('fang') ||
              name.contains('timestar') ||
              name.contains('wing')) {
            print('${matches ? "✅" : "❌ Gefiltert:"} ${card['name']}');
            print('   phraseInName: $phraseInName');
            print('   phraseInArchetype: $phraseInArchetype');
            print('   phraseInDesc: $phraseInDesc');
            print('   Suche nach Phrase: "$searchPhrase"');
          }

          return matches;
        }).toList();
      }

      print('✅ Nach Wort-Filterung: ${filteredResults.length} Karten');

      await cardData.preloadCardImages(filteredResults);
      return filteredResults;
    });
// ============================================================================
// SINGLETON PROVIDERS (werden nur einmal erstellt)
// ============================================================================
final deckSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedArchetypeProvider = StateProvider<String?>((ref) => null);
final deckSearchTriggerProvider = StateProvider<int>(
  (ref) => 0,
); // ✅ DIESEN PROVIDER HINZUFÜGEN

final deckSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final searchQuery = ref.watch(deckSearchQueryProvider);
  final selectedArchetype = ref.watch(selectedArchetypeProvider);
  final searchTrigger = ref.watch(
    deckSearchTriggerProvider,
  ); // ✅ Trigger verwenden
  final deckSearchService = ref.watch(deckSearchServiceProvider);

  // WICHTIG: Nur suchen wenn entweder Suchbegriff ODER Archetype ausgewählt ist
  final hasSearchQuery = searchQuery.isNotEmpty;
  final hasSelectedArchetype =
      selectedArchetype != null && selectedArchetype.isNotEmpty;

  // Wenn keine Suche aktiv, zeige leere Liste
  if (!hasSearchQuery && !hasSelectedArchetype) {
    return [];
  }

  if (hasSelectedArchetype) {
    return deckSearchService.searchDecksByArchetype(selectedArchetype!);
  } else if (hasSearchQuery) {
    return deckSearchService.searchDecks(searchQuery);
  } else {
    return [];
  }
});
// In app_providers.dart - KORRIGIERTE VERSION

// In app_providers.dart - KORRIGIERTE VERSION

/// Provider für CardData Service
final cardDataProvider = Provider<CardData>((ref) {
  return CardData();
});

/// Provider für FirebaseAuthRepository
final authRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Provider für Userdata Service
final userdataProvider = Provider<Userdata>((ref) {
  return Userdata();
});

/// Provider für DeckService
final deckServiceProvider = Provider<DeckService>((ref) {
  return DeckService();
});

/// Provider für DeckSearchService
final deckSearchServiceProvider = Provider<DeckSearchService>((ref) {
  return DeckSearchService();
});

/// Provider für SaveData (SharedPreferences)
final saveDataProvider = Provider<SaveData>((ref) {
  return SaveData();
});

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================

/// Stream Provider für den aktuellen Auth-Status
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

/// Provider für den aktuellen User
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ============================================================================
// THEME PROVIDER
// ============================================================================

/// StateNotifier für Dark Mode
class DarkModeNotifier extends StateNotifier<bool?> {
  final SaveData _saveData;

  DarkModeNotifier(this._saveData) : super(null) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _saveData.loadBool("darkMode");
    state = isDark;
  }

  Future<void> toggleDarkMode(bool value) async {
    state = value;
    await _saveData.saveBool("darkMode", value);
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool?>((ref) {
  final saveData = ref.watch(saveDataProvider);
  return DarkModeNotifier(saveData);
});

// ============================================================================
// NAVIGATION PROVIDER
// ============================================================================

/// StateProvider für den ausgewählten Navigation Index
final selectedIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// PRELOAD DATA PROVIDERS
// ============================================================================

/// FutureProvider für TCG Bannlist
final tcgBannlistProvider = FutureProvider<Map<String, List<dynamic>>>((
  ref,
) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.sortTCGBannCards();
});

/// FutureProvider für OCG Bannlist
final ocgBannlistProvider = FutureProvider<Map<String, List<dynamic>>>((
  ref,
) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.sortOCGBannCards();
});

/// FutureProvider für Types
final typesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('type');
});

/// FutureProvider für Races
final racesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('race');
});

/// FutureProvider für Attributes
final attributesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('attribute');
});

/// FutureProvider für Archetypes
final archetypesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('archetype');
});

// ============================================================================
// USER DATA PROVIDER
// ============================================================================

/// FutureProvider für User-Daten
final userDataProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  userId,
) async {
  final userdata = ref.watch(userdataProvider);
  return await userdata.readUser(userId);
});

// ============================================================================
// CARD SEARCH PROVIDERS
// ============================================================================

/// StateProvider für Card Search Query
final cardSearchQueryProvider = StateProvider<String>((ref) => '');

/// FutureProvider für Card Search Results
final cardSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final query = ref.watch(cardSearchQueryProvider);
  if (query.isEmpty) return [];

  final cardData = ref.watch(cardDataProvider);
  final results = await cardData.ergebniseAnzeigen(query);
  await cardData.preloadCardImages(results);
  return results;
});

// ============================================================================
// DECK SEARCH PROVIDERS
// ============================================================================

/// StateProvider für Deck Search Query

// ============================================================================
// SELECTED CARD/DECK PROVIDERS
// ============================================================================

/// StateProvider für ausgewählte Karte
final selectedCardProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

/// StateProvider für ausgewähltes Deck
final selectedDeckProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// ============================================================================
// FILTER PROVIDERS (für Meta Screen)
// ============================================================================

class FilterState {
  final String? selectedType;
  final String? selectedRace;
  final String? selectedAttribute;
  final String? selectedArchetype;
  final String? selectedBanlistTCG;
  final String? selectedBanlistOCG;
  final String? selectedLevel;
  final String? selectedScale;
  final String? selectedLinkRating;
  final String atkValue;
  final String defValue;
  final String atkOperator;
  final String defOperator;
  final String levelOperator;
  final String scaleOperator;
  final String linkRatingOperator;

  FilterState({
    this.selectedType,
    this.selectedRace,
    this.selectedAttribute,
    this.selectedArchetype,
    this.selectedBanlistTCG,
    this.selectedBanlistOCG,
    this.selectedLevel,
    this.selectedScale,
    this.selectedLinkRating,
    this.atkValue = '',
    this.defValue = '',
    this.atkOperator = '=',
    this.defOperator = '=',
    this.levelOperator = '=',
    this.scaleOperator = '=',
    this.linkRatingOperator = '=',
  });

  FilterState copyWith({
    String? selectedType,
    String? selectedRace,
    String? selectedAttribute,
    String? selectedArchetype,
    String? selectedBanlistTCG,
    String? selectedBanlistOCG,
    String? selectedLevel,
    String? selectedScale,
    String? selectedLinkRating,
    String? atkValue,
    String? defValue,
    String? atkOperator,
    String? defOperator,
    String? levelOperator,
    String? scaleOperator,
    String? linkRatingOperator,
    bool clearType = false,
    bool clearRace = false,
    bool clearAttribute = false,
    bool clearArchetype = false,
    bool clearBanlistTCG = false,
    bool clearBanlistOCG = false,
    bool clearLevel = false,
    bool clearScale = false,
    bool clearLinkRating = false,
  }) {
    return FilterState(
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedRace: clearRace ? null : (selectedRace ?? this.selectedRace),
      selectedAttribute: clearAttribute
          ? null
          : (selectedAttribute ?? this.selectedAttribute),
      selectedArchetype: clearArchetype
          ? null
          : (selectedArchetype ?? this.selectedArchetype),
      selectedBanlistTCG: clearBanlistTCG
          ? null
          : (selectedBanlistTCG ?? this.selectedBanlistTCG),
      selectedBanlistOCG: clearBanlistOCG
          ? null
          : (selectedBanlistOCG ?? this.selectedBanlistOCG),
      selectedLevel: clearLevel ? null : (selectedLevel ?? this.selectedLevel),
      selectedScale: clearScale ? null : (selectedScale ?? this.selectedScale),
      selectedLinkRating: clearLinkRating
          ? null
          : (selectedLinkRating ?? this.selectedLinkRating),
      atkValue: atkValue ?? this.atkValue,
      defValue: defValue ?? this.defValue,
      atkOperator: atkOperator ?? this.atkOperator,
      defOperator: defOperator ?? this.defOperator,
      levelOperator: levelOperator ?? this.levelOperator,
      scaleOperator: scaleOperator ?? this.scaleOperator,
      linkRatingOperator: linkRatingOperator ?? this.linkRatingOperator,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState());

  void updateType(String? value) =>
      state = state.copyWith(selectedType: value, clearType: value == null);
  void updateRace(String? value) =>
      state = state.copyWith(selectedRace: value, clearRace: value == null);
  void updateAttribute(String? value) => state = state.copyWith(
    selectedAttribute: value,
    clearAttribute: value == null,
  );
  void updateArchetype(String? value) => state = state.copyWith(
    selectedArchetype: value,
    clearArchetype: value == null,
  );
  void updateBanlistTCG(String? value) => state = state.copyWith(
    selectedBanlistTCG: value,
    clearBanlistTCG: value == null,
  );
  void updateBanlistOCG(String? value) => state = state.copyWith(
    selectedBanlistOCG: value,
    clearBanlistOCG: value == null,
  );
  void updateLevel(String? value) =>
      state = state.copyWith(selectedLevel: value, clearLevel: value == null);
  void updateScale(String? value) =>
      state = state.copyWith(selectedScale: value, clearScale: value == null);
  void updateLinkRating(String? value) => state = state.copyWith(
    selectedLinkRating: value,
    clearLinkRating: value == null,
  );
  void updateAtkValue(String value) => state = state.copyWith(atkValue: value);
  void updateDefValue(String value) => state = state.copyWith(defValue: value);
  void updateAtkOperator(String value) =>
      state = state.copyWith(atkOperator: value);
  void updateDefOperator(String value) =>
      state = state.copyWith(defOperator: value);
  void updateLevelOperator(String value) =>
      state = state.copyWith(levelOperator: value);
  void updateScaleOperator(String value) =>
      state = state.copyWith(scaleOperator: value);
  void updateLinkRatingOperator(String value) =>
      state = state.copyWith(linkRatingOperator: value);

  void reset() => state = FilterState();
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((
  ref,
) {
  return FilterNotifier();
});

/// StateProvider für Filter Search Trigger
final filterSearchTriggerProvider = StateProvider<int>((ref) => 0);

/// FutureProvider für Filter Search Results
final filterSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  // Watch trigger to force reload
  ref.watch(filterSearchTriggerProvider);

  final filterState = ref.watch(filterProvider);
  final cardData = ref.watch(cardDataProvider);

  // Prüfe ob mindestens ein Filter gesetzt ist
  if (filterState.selectedType == null &&
      filterState.selectedRace == null &&
      filterState.selectedAttribute == null &&
      filterState.selectedArchetype == null &&
      filterState.selectedLevel == null &&
      filterState.atkValue.isEmpty &&
      filterState.defValue.isEmpty &&
      filterState.selectedScale == null &&
      filterState.selectedLinkRating == null &&
      filterState.selectedBanlistTCG == null &&
      filterState.selectedBanlistOCG == null) {
    return [];
  }

  int? levelValue;
  String? levelOperatorValue;
  int? scaleValue;
  String? scaleOperatorValue;
  int? linkRatingValue;
  String? linkRatingOperatorValue;
  String? atkFilter;
  String? defFilter;

  if (filterState.selectedLevel != null) {
    levelValue = int.tryParse(filterState.selectedLevel!);
    levelOperatorValue = filterState.levelOperator;
  }
  if (filterState.selectedScale != null) {
    scaleValue = int.tryParse(filterState.selectedScale!);
    scaleOperatorValue = filterState.scaleOperator;
  }
  if (filterState.selectedLinkRating != null) {
    linkRatingValue = int.tryParse(filterState.selectedLinkRating!);
    linkRatingOperatorValue = filterState.linkRatingOperator;
  }
  if (filterState.atkValue.isNotEmpty) {
    final atkOp = filterState.atkOperator == 'min'
        ? '>='
        : filterState.atkOperator == 'max'
        ? '<='
        : '=';
    atkFilter = '$atkOp${filterState.atkValue}';
  }
  if (filterState.defValue.isNotEmpty) {
    final defOp = filterState.defOperator == 'min'
        ? '>='
        : filterState.defOperator == 'max'
        ? '<='
        : '=';
    defFilter = '$defOp${filterState.defValue}';
  }

  final results = await cardData.searchWithFilters(
    type: filterState.selectedType,
    race: filterState.selectedRace,
    attribute: filterState.selectedAttribute,
    archetype: filterState.selectedArchetype,
    level: levelValue,
    levelOperator: levelOperatorValue,
    linkRating: linkRatingValue,
    linkRatingOperator: linkRatingOperatorValue,
    scale: scaleValue,
    scaleOperator: scaleOperatorValue,
    atk: atkFilter,
    def: defFilter,
    banlistTCG: filterState.selectedBanlistTCG,
    banlistOCG: filterState.selectedBanlistOCG,
  );

  await cardData.preloadCardImages(results);
  return results;
});

// ============================================================================
// SHOW FILTERS STATE
// ============================================================================

final showFiltersProvider = StateProvider<bool>((ref) => true);
final usernameProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      final username = doc.data()?['username'] as String?;
      return username ?? 'Unknown';
    }
    return 'Unknown';
  } catch (e) {
    return 'Unknown';
  }
});
