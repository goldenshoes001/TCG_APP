// lib/providers/calculator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
      return CalculatorNotifier();
    });

class CalculatorState {
  final String deckSize;
  final String handSize;
  final List<String> targetCopies;
  final bool isAndMode;
  final double probability;

  CalculatorState({
    this.deckSize = "40",
    this.handSize = "5",
    this.targetCopies = const ["3"],
    this.isAndMode = false,
    this.probability = 0.0,
  });

  CalculatorState copyWith({
    String? deckSize,
    String? handSize,
    List<String>? targetCopies,
    bool? isAndMode,
    double? probability,
  }) {
    return CalculatorState(
      deckSize: deckSize ?? this.deckSize,
      handSize: handSize ?? this.handSize,
      targetCopies: targetCopies ?? this.targetCopies,
      isAndMode: isAndMode ?? this.isAndMode,
      probability: probability ?? this.probability,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  CalculatorNotifier() : super(CalculatorState()) {
    _calculateProbability();
  }

  void updateDeckSize(String value) {
    state = state.copyWith(deckSize: value);
    _calculateProbability();
  }

  void updateHandSize(String value) {
    state = state.copyWith(handSize: value);
    _calculateProbability();
  }

  void updateTargetCopy(int index, String value) {
    final newTargetCopies = List<String>.from(state.targetCopies);
    if (index < newTargetCopies.length) {
      newTargetCopies[index] = value;
    }
    state = state.copyWith(targetCopies: newTargetCopies);
    _calculateProbability();
  }

  void addTargetSet() {
    final newTargetCopies = List<String>.from(state.targetCopies)..add("1");
    final newIsAndMode = newTargetCopies.length > 1 ? true : state.isAndMode;
    state = state.copyWith(
      targetCopies: newTargetCopies,
      isAndMode: newIsAndMode,
    );
    _calculateProbability();
  }

  void removeTargetSet(int index) {
    if (state.targetCopies.length <= 1) return;
    final newTargetCopies = List<String>.from(state.targetCopies)
      ..removeAt(index);
    final newIsAndMode = newTargetCopies.length > 1 ? state.isAndMode : false;
    state = state.copyWith(
      targetCopies: newTargetCopies,
      isAndMode: newIsAndMode,
    );
    _calculateProbability();
  }

  void toggleMode() {
    if (state.targetCopies.length > 1) {
      state = state.copyWith(isAndMode: !state.isAndMode);
      _calculateProbability();
    }
  }

  // Binomial coefficient helper function
  BigInt _combinations(int n, int k) {
    if (k < 0 || k > n) return BigInt.zero;
    if (k == 0 || k == n) return BigInt.one;
    if (k > n ~/ 2) k = n - k;

    BigInt res = BigInt.one;
    for (int i = 1; i <= k; i++) {
      res = res * BigInt.from(n - i + 1) ~/ BigInt.from(i);
    }
    return res;
  }

  double _probNoneOfSet(
    int D,
    int H,
    List<int> indicesToExclude,
    List<String> allTargetCopies,
  ) {
    int sumOfExcludedCopies = 0;
    for (int index in indicesToExclude) {
      sumOfExcludedCopies += int.tryParse(allTargetCopies[index]) ?? 0;
    }

    final deckSizeMinusExcluded = D - sumOfExcludedCopies;
    if (deckSizeMinusExcluded < H || deckSizeMinusExcluded < 0) {
      return 0.0;
    }

    final combinationsOfNotDrawing = _combinations(deckSizeMinusExcluded, H);
    final totalCombinations = _combinations(D, H);

    if (totalCombinations > BigInt.zero) {
      return combinationsOfNotDrawing.toDouble() / totalCombinations.toDouble();
    }
    return 0.0;
  }

  void _calculateProbAND(int D, int H) {
    final targetCopies = state.targetCopies;
    final N = targetCopies.length;

    if (N > H) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    double probNone = 0.0;
    for (int i = 1; i < (1 << N); i++) {
      List<int> currentSetIndices = [];
      int setSize = 0;
      for (int j = 0; j < N; j++) {
        if ((i & (1 << j)) != 0) {
          currentSetIndices.add(j);
          setSize++;
        }
      }

      final probNoneCurrentSet = _probNoneOfSet(
        D,
        H,
        currentSetIndices,
        targetCopies,
      );
      final sign = (setSize % 2 == 1) ? 1.0 : -1.0;
      probNone += sign * probNoneCurrentSet;
    }

    final finalProbability = 1.0 - probNone;
    state = state.copyWith(
      probability: finalProbability.isFinite ? finalProbability : 0.0,
    );
  }

  void _calculateProbOR(int D, int H, int T) {
    if (D <= 0 || T <= 0 || H <= 0 || H > D || T > D) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    final combinationsOfNotDrawing = _combinations(D - T, H);
    final totalCombinations = _combinations(D, H);

    double probNotDrawing = 0.0;
    if (totalCombinations > BigInt.zero) {
      probNotDrawing =
          combinationsOfNotDrawing.toDouble() / totalCombinations.toDouble();
    }

    final finalProbability = 1.0 - probNotDrawing;
    state = state.copyWith(
      probability: finalProbability.isFinite ? finalProbability : 0.0,
    );
  }

  void _calculateProbability() {
    final D = int.tryParse(state.deckSize) ?? 40;
    final H = int.tryParse(state.handSize) ?? 5;

    // Prüfe ob targetCopies leer ist
    if (state.targetCopies.isEmpty) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    int T = 0;
    for (String copy in state.targetCopies) {
      T += int.tryParse(copy) ?? 0;
    }

    if (D <= 0 || H <= 0 || T > D || H > D) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    if (state.targetCopies.length == 1) {
      _calculateProbOR(D, H, T);
    } else if (state.isAndMode) {
      _calculateProbAND(D, H);
    } else {
      _calculateProbOR(D, H, T);
    }
  }
}
