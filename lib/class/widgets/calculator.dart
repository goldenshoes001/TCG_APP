// calculator.dart - mit reinen Text-Eingabefeldern
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/providers/calculator_provider.dart';

class ProbabilityCalculator extends ConsumerWidget {
  const ProbabilityCalculator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);

    final hasMultipleTargets = state.targetCopies.length > 1;
    final handSizeInt = int.tryParse(state.handSize) ?? 0;
    final isStrictlyImpossible =
        state.isAndMode &&
        hasMultipleTargets &&
        state.targetCopies.length > handSizeInt;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Probability Calculator'),
                  const SizedBox(height: 8),
                  Text('Calculate drawing chances for your deck'),
                ],
              ),
            ),
          ),

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
                          child: _NumberInputField(
                            label: 'Deck Size',
                            value: state.deckSize,
                            onChanged: notifier.updateDeckSize,
                            hintText: '40',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _NumberInputField(
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
            child: Card(
              child: Row(
                children: [
                  Text('Target  Cards'),
                  const Spacer(),
                  if (state.targetCopies.length < 10)
                    FilledButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Card'),
                      onPressed: notifier.addTargetSet,
                    ),
                ],
              ),
            ),
          ),

          // Target Cards ListView
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _TargetCardItem(
                index: index,
                copies: state.targetCopies[index],
                onCopiesChanged: (value) =>
                    notifier.updateTargetCopy(index, value),
                onRemove: state.targetCopies.length > 1
                    ? () => notifier.removeTargetSet(index)
                    : null,
              );
            }, childCount: state.targetCopies.length),
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
                      Text('Calculation Mode'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(state.isAndMode ? 'AND Mode' : 'OR Mode'),
                                const SizedBox(height: 4),
                                Text(
                                  state.isAndMode
                                      ? 'Draw at least 1 from EACH card set'
                                      : 'Draw at least 1 from ANY card set',
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.isAndMode,
                            onChanged: (_) => notifier.toggleMode(),
                            activeTrackColor: Colors.green,
                            activeColor: Colors.white,
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
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      state.isAndMode && hasMultipleTargets
                          ? 'CHANCE TO DRAW ALL CARDS'
                          : 'CHANCE TO DRAW ANY CARD',
                    ),
                    const SizedBox(height: 12),
                    Text('${(state.probability * 100).toStringAsFixed(1)}%'),
                    if (isStrictlyImpossible)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
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
                                  'Impossible: Need ${state.targetCopies.length} different cards but only draw $handSizeInt',

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

class _NumberInputField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final String hintText;

  const _NumberInputField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.hintText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            // Setzt den Standard-Border für enabled/unfocused, disabled, etc.
            border: border,
            enabledBorder: border,
            // ⚠️ enabledBorder: border; <--- DIESE ZEILE ENTFERNEN!

            // Überschreibt den Border nur, wenn das Feld den Fokus hat
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            hintText: hintText, // Hint Text wird verwendet
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetCardItem extends StatelessWidget {
  final int index;
  final String copies;
  final Function(String) onCopiesChanged;
  final VoidCallback? onRemove;

  const _TargetCardItem({
    required this.index,
    required this.copies,
    required this.onCopiesChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Index Badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${index + 1}')),
            ),
            const SizedBox(width: 16),

            // Card Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Card ${index + 1}'), Text('Copies in deck')],
              ),
            ),

            // Copies Input Field
            SizedBox(
              width: 80,
              child: TextField(
                controller: TextEditingController(text: copies),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  hintText: '3',
                ),
                onChanged: onCopiesChanged,
              ),
            ),

            // Remove Button
            if (onRemove != null) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onRemove,
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
