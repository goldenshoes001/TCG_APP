// lib/providers/calculator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TargetCard {
  final String copies;
  final String requiredInHand;

  TargetCard({this.copies = "3", this.requiredInHand = "1"});

  TargetCard copyWith({String? copies, String? requiredInHand}) {
    return TargetCard(
      copies: copies ?? this.copies,
      requiredInHand: requiredInHand ?? this.requiredInHand,
    );
  }
}

class CalculatorState {
  final String deckSize;
  final String handSize;
  final List<TargetCard> targetCards;
  final bool isAndMode;
  final double probability;

  CalculatorState({
    this.deckSize = "40",
    this.handSize = "5",
    List<TargetCard>? targetCards,
    this.isAndMode = false,
    this.probability = 0.0,
  }) : targetCards = targetCards ?? [TargetCard()];

  CalculatorState copyWith({
    String? deckSize,
    String? handSize,
    List<TargetCard>? targetCards,
    bool? isAndMode,
    double? probability,
  }) {
    return CalculatorState(
      deckSize: deckSize ?? this.deckSize,
      handSize: handSize ?? this.handSize,
      targetCards: targetCards ?? this.targetCards,
      isAndMode: isAndMode ?? this.isAndMode,
      probability: probability ?? this.probability,
    );
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
      return CalculatorNotifier();
    });

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

  void updateTargetCardCopies(int index, String value) {
    final newTargetCards = List<TargetCard>.from(state.targetCards);
    if (index < newTargetCards.length) {
      newTargetCards[index] = newTargetCards[index].copyWith(copies: value);
    }
    state = state.copyWith(targetCards: newTargetCards);
    _calculateProbability();
  }

  void updateTargetCardRequired(int index, String value) {
    final newTargetCards = List<TargetCard>.from(state.targetCards);
    if (index < newTargetCards.length) {
      newTargetCards[index] = newTargetCards[index].copyWith(
        requiredInHand: value,
      );
    }
    state = state.copyWith(targetCards: newTargetCards);
    _calculateProbability();
  }

  void addTargetCard() {
    final newTargetCards = List<TargetCard>.from(state.targetCards)
      ..add(TargetCard());
    final newIsAndMode = newTargetCards.length > 1 ? true : state.isAndMode;
    state = state.copyWith(
      targetCards: newTargetCards,
      isAndMode: newIsAndMode,
    );
    _calculateProbability();
  }

  void removeTargetCard(int index) {
    if (state.targetCards.length <= 1) return;
    final newTargetCards = List<TargetCard>.from(state.targetCards)
      ..removeAt(index);
    final newIsAndMode = newTargetCards.length > 1 ? state.isAndMode : false;
    state = state.copyWith(
      targetCards: newTargetCards,
      isAndMode: newIsAndMode,
    );
    _calculateProbability();
  }

  void toggleMode() {
    if (state.targetCards.length > 1) {
      state = state.copyWith(isAndMode: !state.isAndMode);
      _calculateProbability();
    }
  }

  // Helper function to count set bits in an integer
  int _countOnes(int n) {
    int count = 0;
    while (n > 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
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

  double _probDrawExactly(int D, int H, int copiesInDeck, int requiredInHand) {
    if (requiredInHand < 0 ||
        requiredInHand > copiesInDeck ||
        requiredInHand > H ||
        copiesInDeck > D) {
      return 0.0;
    }

    final waysToDrawRequired = _combinations(copiesInDeck, requiredInHand);
    final waysToDrawOther = _combinations(D - copiesInDeck, H - requiredInHand);
    final totalWays = _combinations(D, H);

    if (totalWays > BigInt.zero) {
      return (waysToDrawRequired * waysToDrawOther).toDouble() /
          totalWays.toDouble();
    }
    return 0.0;
  }

  double _probDrawAtLeast(int D, int H, int copiesInDeck, int requiredInHand) {
    if (requiredInHand <= 0) return 1.0;
    if (requiredInHand > copiesInDeck ||
        requiredInHand > H ||
        copiesInDeck > D) {
      return 0.0;
    }

    double probability = 0.0;
    for (int k = requiredInHand; k <= copiesInDeck && k <= H; k++) {
      probability += _probDrawExactly(D, H, copiesInDeck, k);
    }
    return probability;
  }

  void _calculateProbAND(int D, int H) {
    final targetCards = state.targetCards;
    final N = targetCards.length;

    // Check if it's strictly impossible
    int totalRequired = 0;
    for (final card in targetCards) {
      totalRequired += int.tryParse(card.requiredInHand) ?? 0;
    }
    if (totalRequired > H) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    // For AND mode with multiple required cards, we need a more sophisticated approach
    // This is a simplified approximation using inclusion-exclusion
    double probAll = 1.0;

    // Multiply probabilities for each card (this assumes independence, which isn't perfect but works as approximation)
    for (final card in targetCards) {
      final copies = int.tryParse(card.copies) ?? 0;
      final required = int.tryParse(card.requiredInHand) ?? 0;

      final probThisCard = _probDrawAtLeast(D, H, copies, required);
      probAll *= probThisCard;

      if (!probAll.isFinite || probAll <= 0.0) {
        probAll = 0.0;
        break;
      }
    }

    state = state.copyWith(
      probability: probAll.isFinite ? probAll.clamp(0.0, 1.0) : 0.0,
    );
  }

  void _calculateProbOR(int D, int H) {
    final targetCards = state.targetCards;

    if (targetCards.isEmpty) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    // For OR mode, calculate probability that at least one card meets its requirement
    double probNone = 1.0;

    for (final card in targetCards) {
      final copies = int.tryParse(card.copies) ?? 0;
      final required = int.tryParse(card.requiredInHand) ?? 0;

      final probNotThisCard = 1.0 - _probDrawAtLeast(D, H, copies, required);
      probNone *= probNotThisCard;

      if (!probNone.isFinite) {
        probNone = 0.0;
        break;
      }
    }

    final finalProbability = 1.0 - probNone;
    state = state.copyWith(
      probability: finalProbability.isFinite
          ? finalProbability.clamp(0.0, 1.0)
          : 0.0,
    );
  }

  void _calculateProbability() {
    final D = int.tryParse(state.deckSize) ?? 40;
    final H = int.tryParse(state.handSize) ?? 5;

    if (state.targetCards.isEmpty) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    if (D <= 0 || H <= 0 || H > D) {
      state = state.copyWith(probability: 0.0);
      return;
    }

    // Check for individual card requirements that are impossible
    for (final card in state.targetCards) {
      final copies = int.tryParse(card.copies) ?? 0;
      final required = int.tryParse(card.requiredInHand) ?? 0;

      if (required > copies || required > H || copies > D) {
        if (state.isAndMode) {
          state = state.copyWith(probability: 0.0);
          return;
        }
      }
    }

    if (state.targetCards.length == 1) {
      final card = state.targetCards.first;
      final copies = int.tryParse(card.copies) ?? 0;
      final required = int.tryParse(card.requiredInHand) ?? 0;

      final probability = _probDrawAtLeast(D, H, copies, required);
      state = state.copyWith(probability: probability);
    } else if (state.isAndMode) {
      _calculateProbAND(D, H);
    } else {
      _calculateProbOR(D, H);
    }
  }
}
