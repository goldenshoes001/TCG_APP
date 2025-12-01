// app_providers.dart - KORRIGIERTE VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/Firebase/interfaces/FirebaseAuthRepository.dart';
import 'package:tcg_app/class/Firebase/user/user.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:tcg_app/class/widgets/deck_search_service.dart';
import 'package:tcg_app/class/sharedPreference.dart';

// ============================================================================
// ✅ PAGINATION STATE & NOTIFIER
// ============================================================================

class DecksPaginationState {
  final List<Map<String, dynamic>> decks;
  final bool hasMore;
  final bool isLoading;
  final DocumentSnapshot? lastDocument;

  DecksPaginationState({
    required this.decks,
    required this.hasMore,
    required this.isLoading,
    this.lastDocument,
  });

  DecksPaginationState copyWith({
    List<Map<String, dynamic>>? decks,
    bool? hasMore,
    bool? isLoading,
    DocumentSnapshot? lastDocument,
  }) {
    return DecksPaginationState(
      decks: decks ?? this.decks,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

class DecksPaginationNotifier extends StateNotifier<DecksPaginationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 50;

  DecksPaginationNotifier()
    : super(DecksPaginationState(decks: [], hasMore: true, isLoading: false));

  Future<void> loadFirstPage() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final snapshot = await _firestore
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize)
          .get();

      final decks = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      state = DecksPaginationState(
        decks: decks,
        hasMore: decks.length == _pageSize,
        isLoading: false,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      Query query = _firestore
          .collection('decks')
          .orderBy('updatedAt', descending: true)
          .limit(_pageSize);

      if (state.lastDocument != null) {
        query = query.startAfterDocument(state.lastDocument!);
      }

      final snapshot = await query.get();

      final newDecks = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      final allDecks = [...state.decks, ...newDecks];

      state = DecksPaginationState(
        decks: allDecks,
        hasMore: newDecks.length == _pageSize,
        isLoading: false,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void handleExternalUpdate(List<Map<String, dynamic>> updatedDecks) {
    if (updatedDecks.isEmpty) return;

    final currentDecks = state.decks;

    // Erstelle eine Map der updated Decks für schnellen Zugriff
    final updatedDecksMap = {
      for (var deck in updatedDecks) _getDeckId(deck): deck,
    };

    final List<Map<String, dynamic>> newDecksList = [];
    final Set<String> processedDeckIds = {};

    for (final updatedDeck in updatedDecks) {
      final deckId = _getDeckId(updatedDeck);
      processedDeckIds.add(deckId);
      newDecksList.add(updatedDeck);
    }

    for (final currentDeck in currentDecks) {
      final deckId = _getDeckId(currentDeck);
      if (!processedDeckIds.contains(deckId)) {
        if (updatedDecksMap.containsKey(deckId)) {
          newDecksList.add(updatedDecksMap[deckId]!);
        } else {
          newDecksList.add(currentDeck);
        }
      }
    }

    newDecksList.sort((a, b) {
      final aUpdated = a['updatedAt'] as Timestamp?;
      final bUpdated = b['updatedAt'] as Timestamp?;

      if (aUpdated != null && bUpdated != null) {
        return bUpdated.compareTo(aUpdated);
      }
      return 0;
    });

    if (_hasDecksChanged(currentDecks, newDecksList)) {
      state = state.copyWith(decks: newDecksList);
    }
  }

  String _getDeckId(Map<String, dynamic> deck) {
    return deck['deckId'] ?? deck['_documentId'] ?? '';
  }

  bool _hasDecksChanged(
    List<Map<String, dynamic>> oldDecks,
    List<Map<String, dynamic>> newDecks,
  ) {
    if (oldDecks.length != newDecks.length) return true;

    for (int i = 0; i < oldDecks.length; i++) {
      final oldDeck = oldDecks[i];
      final newDeck = newDecks[i];

      final oldId = _getDeckId(oldDeck);
      final newId = _getDeckId(newDeck);

      if (oldId != newId) return true;

      if (oldDeck['updatedAt'] != newDeck['updatedAt']) return true;
      if (oldDeck['deckName'] != newDeck['deckName']) return true;
    }

    return false;
  }

  Future<void> refresh() async {
    state = DecksPaginationState(decks: [], hasMore: true, isLoading: false);
    await loadFirstPage();
  }

  void addDeck(Map<String, dynamic> deck) {
    final newDecks = [deck, ...state.decks];
    state = state.copyWith(decks: newDecks);
  }

  void updateDeck(String deckId, Map<String, dynamic> updatedDeck) {
    final newDecks = state.decks.map((deck) {
      if (_getDeckId(deck) == deckId) {
        return updatedDeck;
      }
      return deck;
    }).toList();

    state = state.copyWith(decks: newDecks);
  }

  void removeDeck(String deckId) {
    final newDecks = state.decks.where((deck) {
      return _getDeckId(deck) != deckId;
    }).toList();

    state = state.copyWith(decks: newDecks);
  }
}

// ============================================================================
// ✅ STREAM & PAGINATION PROVIDERS
// ============================================================================

final decksUpdatesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('decks')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, '_documentId': doc.id};
        }).toList();
      });
});

final decksPaginationProvider =
    StateNotifierProvider<DecksPaginationNotifier, DecksPaginationState>((ref) {
      final notifier = DecksPaginationNotifier();

      // Korrigierte Stream-Listener Logik
      final stream = ref.watch(decksUpdatesStreamProvider);

      stream.when(
        data: (updatedDecks) {
          notifier.handleExternalUpdate(updatedDecks);
        },
        loading: () {},
        error: (error, stack) {},
      );

      return notifier;
    });

final refreshableDecksProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final paginationState = ref.watch(decksPaginationProvider);
  return paginationState.decks;
});

// ============================================================================
// ARCHETYPE PROVIDERS
// ============================================================================

final preloadedDeckArchetypesProvider = StateProvider<List<String>>((ref) {
  final decks = ref.watch(refreshableDecksProvider);

  final Set<String> archetypes = {};
  for (var deck in decks) {
    final archetype = deck['archetype'] as String? ?? '';
    if (archetype.isNotEmpty) {
      final archetypeList = archetype
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty);
      archetypes.addAll(archetypeList);
    }
  }

  final sortedArchetypes = archetypes.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return sortedArchetypes;
});

final preloadedTypesProvider = StateProvider<List<String>?>((ref) => null);
final preloadedRacesProvider = StateProvider<List<String>?>((ref) => null);
final preloadedAttributesProvider = StateProvider<List<String>?>((ref) => null);
final preloadedArchetypesProvider = StateProvider<List<String>?>((ref) => null);

final combinedTypesProvider = Provider<List<String>>((ref) {
  final preloaded = ref.watch(preloadedTypesProvider);
  if (preloaded != null) return preloaded;
  final asyncTypes = ref.watch(typesProvider);
  return asyncTypes.valueOrNull ?? [];
});

final combinedRacesProvider = Provider<List<String>>((ref) {
  final preloaded = ref.watch(preloadedRacesProvider);
  if (preloaded != null) return preloaded;
  final asyncRaces = ref.watch(racesProvider);
  return asyncRaces.valueOrNull ?? [];
});

final combinedAttributesProvider = Provider<List<String>>((ref) {
  final preloaded = ref.watch(preloadedAttributesProvider);
  if (preloaded != null) return preloaded;
  final asyncAttributes = ref.watch(attributesProvider);
  return asyncAttributes.valueOrNull ?? [];
});

final combinedArchetypesProvider = Provider<List<String>>((ref) {
  final preloaded = ref.watch(preloadedArchetypesProvider);
  if (preloaded != null) return preloaded;
  final asyncArchetypes = ref.watch(archetypesProvider);
  return asyncArchetypes.valueOrNull ?? [];
});

// ============================================================================
// COMBINED SEARCH RESULTS PROVIDER
// ============================================================================

final combinedSearchResultsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final query = ref.watch(cardSearchQueryProvider);
      final filterState = ref.watch(filterProvider);
      final cardData = ref.watch(cardDataProvider);

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

      if (!hasQuery && !hasFilters) {
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

      await cardData.preloadCardImages(results);
      return results;
    });

// ============================================================================
// DECK SEARCH PROVIDERS
// ============================================================================

final deckSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedArchetypeProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// SINGLETON PROVIDERS
// ============================================================================

final cardDataProvider = Provider<CardData>((ref) => CardData());
final authRepositoryProvider = Provider<FirebaseAuthRepository>(
  (ref) => FirebaseAuthRepository(),
);
final userdataProvider = Provider<Userdata>((ref) => Userdata());
final deckServiceProvider = Provider<DeckService>((ref) => DeckService());
final deckSearchServiceProvider = Provider<DeckSearchService>(
  (ref) => DeckSearchService(),
);
final saveDataProvider = Provider<SaveData>((ref) => SaveData());

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

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

final selectedIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// PRELOAD DATA PROVIDERS
// ============================================================================

final tcgBannlistProvider = FutureProvider<Map<String, List<dynamic>>>((
  ref,
) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.sortTCGBannCards();
});

final ocgBannlistProvider = FutureProvider<Map<String, List<dynamic>>>((
  ref,
) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.sortOCGBannCards();
});

final typesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('type');
});

final racesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('race');
});

final attributesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('attribute');
});

final archetypesProvider = FutureProvider<List<String>>((ref) async {
  final cardData = ref.watch(cardDataProvider);
  return await cardData.getFacetValues('archetype');
});

// ============================================================================
// USER DATA PROVIDER
// ============================================================================

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

final cardSearchQueryProvider = StateProvider<String>((ref) => '');

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
// SELECTED CARD/DECK PROVIDERS
// ============================================================================

final selectedCardProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);
final selectedDeckProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

// ============================================================================
// FILTER PROVIDERS
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

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>(
  (ref) => FilterNotifier(),
);
final filterSearchTriggerProvider = StateProvider<int>((ref) => 0);

final filterSearchResultsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  ref.watch(filterSearchTriggerProvider);

  final filterState = ref.watch(filterProvider);
  final cardData = ref.watch(cardDataProvider);

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
