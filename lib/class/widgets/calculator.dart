// calculator.dart - mit robustem Fokusmanagement für alle Felder
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/providers/calculator_provider.dart';

class ProbabilityCalculator extends ConsumerWidget {
  const ProbabilityCalculator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);

    final hasMultipleTargets = state.targetCards.length > 1;
    final handSizeInt = int.tryParse(state.handSize) ?? 0;
    final isStrictlyImpossible =
        state.isAndMode &&
        hasMultipleTargets &&
        state.targetCards.length > handSizeInt;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header

          // Deck Configuration
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deck Configuration'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          // HIER: _DeckConfigInputField statt _NumberInputField verwenden
                          child: _DeckConfigInputField(
                            label: 'Deck Size',
                            value: state.deckSize,
                            onChanged: notifier.updateDeckSize,
                            hintText: '40',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          // HIER: _DeckConfigInputField statt _NumberInputField verwenden
                          child: _DeckConfigInputField(
                            label: 'Hand Size',
                            value: state.handSize,
                            onChanged: notifier.updateHandSize,
                            hintText: '5',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Target Cards Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text('Target Cards'),
                      const Spacer(),
                      if (state.targetCards.length < 10)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).cardColor,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Card'),
                          onPressed: notifier.addTargetCard,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Target Cards ListView
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _TargetCardItem(
                key: ValueKey('target_card_$index'),
                index: index,
                targetCard: state.targetCards[index],
                onCopiesChanged: (value) =>
                    notifier.updateTargetCardCopies(index, value),
                onRequiredChanged: (value) =>
                    notifier.updateTargetCardRequired(index, value),
                onRemove: state.targetCards.length > 1
                    ? () => notifier.removeTargetCard(index)
                    : null,
              );
            }, childCount: state.targetCards.length),
          ),

          // Mode Selector
          if (hasMultipleTargets)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(state.isAndMode ? 'AND Mode' : 'OR Mode'),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.isAndMode,
                            onChanged: (_) => notifier.toggleMode(),
                            activeTrackColor: Theme.of(context).cardColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Result
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('${(state.probability * 100).toStringAsFixed(1)}%'),
                    if (isStrictlyImpossible)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Impossible: Need ${state.targetCards.length} different cards but only draw $handSizeInt',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// STATEFUL WIDGET für Deck/Hand Size
class _DeckConfigInputField extends StatefulWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String hintText;

  const _DeckConfigInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hintText,
    Key? key,
  }) : super(key: key);

  @override
  State<_DeckConfigInputField> createState() => _DeckConfigInputFieldState();
}

class _DeckConfigInputFieldState extends State<_DeckConfigInputField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Controller im State initialisieren
    _controller = TextEditingController(text: widget.value);
    // Setzen Sie den Cursor ans Ende
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  // Hilfsfunktion zur Synchronisierung des Controllers
  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text != value) {
      // Nur aktualisieren, wenn der Text von Riverpod abweicht
      controller.value = controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void didUpdateWidget(_DeckConfigInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Führt die Synchronisierung nur durch, wenn das Feld NICHT fokussiert ist.
    if (!_focusNode.hasFocus) {
      _syncControllerText(_controller, widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          onChanged: (value) {
            // 1. Riverpod State aktualisieren (löst Rebuild aus)
            widget.onChanged(value);
            // 2. FIX: Fokus-Wiederherstellung verzögern, um Absturz zu vermeiden
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusNode.requestFocus();
            });
          },
          onFieldSubmitted: (value) => widget.onChanged(value),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          focusNode: _focusNode,
          decoration: InputDecoration(
            border: border,
            focusedBorder: border,
            enabledBorder: border,
            hintText: widget.hintText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetCardItem extends StatefulWidget {
  final int index;
  final TargetCard targetCard;
  final Function(String) onCopiesChanged;
  final Function(String) onRequiredChanged;
  final VoidCallback? onRemove;

  const _TargetCardItem({
    required this.index,
    required this.targetCard,
    required this.onCopiesChanged,
    required this.onRequiredChanged,
    this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  State<_TargetCardItem> createState() => _TargetCardItemState();
}

class _TargetCardItemState extends State<_TargetCardItem> {
  late TextEditingController _copiesController;
  late TextEditingController _requiredController;

  // FocusNodes sofort initialisieren (final)
  final FocusNode _copiesFocusNode = FocusNode();
  final FocusNode _requiredFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Controller initialisieren
    _copiesController = TextEditingController(text: widget.targetCard.copies);
    _requiredController = TextEditingController(
      text: widget.targetCard.requiredInHand,
    );

    // Setzen Sie den Cursor ans Ende, um die Eingabe zu erleichtern
    _copiesController.selection = TextSelection.collapsed(
      offset: _copiesController.text.length,
    );
    _requiredController.selection = TextSelection.collapsed(
      offset: _requiredController.text.length,
    );
  }

  // Funktion zur Korrektur des Controllers nach Rebuilds, wenn nicht fokussiert
  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text != value) {
      // Nur aktualisieren, wenn der Text von Riverpod abweicht
      controller.value = controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void didUpdateWidget(_TargetCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronisierung nur, wenn das Feld nicht fokussiert ist.
    if (!_copiesFocusNode.hasFocus) {
      _syncControllerText(_copiesController, widget.targetCard.copies);
    }
    if (!_requiredFocusNode.hasFocus) {
      _syncControllerText(
        _requiredController,
        widget.targetCard.requiredInHand,
      );
    }
  }

  @override
  void dispose() {
    _copiesController.dispose();
    _requiredController.dispose();
    _copiesFocusNode.dispose();
    _requiredFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Card(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
      elevation: 0,

      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 0, bottom: 10),
        child: Row(
          children: [
            // Card Number
            Text(
              'Card ${widget.index + 1}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 16),

            // Copies Input Field
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copies',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _copiesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    focusNode: _copiesFocusNode,
                    decoration: InputDecoration(
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      hintText: '1',
                    ),
                    onChanged: (value) {
                      // 1. Riverpod State aktualisieren (löst Rebuild aus)
                      widget.onCopiesChanged(value);
                      // 2. FIX: Fokus-Wiederherstellung verzögern
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _copiesFocusNode.requestFocus();
                      });
                    },
                    onSubmitted: (value) {
                      // Stellt sicher, dass die Berechnung bei Enter abgeschlossen wird
                      widget.onCopiesChanged(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Required Input Field
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _requiredController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    focusNode: _requiredFocusNode,
                    decoration: InputDecoration(
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      hintText: '1',
                    ),
                    onChanged: (value) {
                      // 1. Riverpod State aktualisieren (löst Rebuild aus)
                      widget.onRequiredChanged(value);
                      // 2. FIX: Fokus-Wiederherstellung verzögern
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _requiredFocusNode.requestFocus();
                      });
                    },
                    onSubmitted: (value) {
                      // Stellt sicher, dass die Berechnung bei Enter abgeschlossen wird
                      widget.onRequiredChanged(value);
                    },
                  ),
                ],
              ),
            ),

            // Remove Button
            if (widget.onRemove != null) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: widget.onRemove,
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
