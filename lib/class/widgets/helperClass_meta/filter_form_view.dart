// filter_form_view.dart - FINAL AUFGERÄUMT

import 'package:flutter/material.dart';
import 'package:tcg_app/class/widgets/helperClass_meta/filter_dropdown.dart';
import 'package:tcg_app/class/widgets/helperClass_meta/operator_dropdown.dart';
import 'package:tcg_app/class/widgets/helperClass_meta/operator_text_input.dart';

class FilterFormView extends StatelessWidget {
  // Listen
  final List<String> types;
  final List<String> races;
  final List<String> attributes;
  final List<String> archetypes;
  final List<String> banlistStatuses;

  // Feste Werte
  final List<String> operators = const ['min', '=', 'max'];
  final List<String> levelItems = List.generate(
    13,
    (index) => index.toString(),
  );
  final List<String> scaleItems = List.generate(
    14,
    (index) => index.toString(),
  );
  final List<String> linkRatingItems = List.generate(
    8,
    (index) => (index + 1).toString(),
  );

  // Ausgewählte Werte (Props)
  final String? selectedType;
  final String? selectedRace;
  final String? selectedAttribute;
  final String? selectedArchetype;
  final String? selectedLevel;
  final String? selectedScale;
  final String? selectedLinkRating;
  final String? selectedBanlistTCG;
  final String? selectedBanlistOCG;

  // Controller
  final TextEditingController atkController;
  final TextEditingController defController;

  // Operatoren
  final String atkOperator;
  final String defOperator;
  final String levelOperator;
  final String scaleOperator;
  final String linkRatingOperator;

  // Callbacks (Setter-Funktionen)
  final void Function(String?) onSelectedTypeChanged;
  final void Function(String?) onSelectedRaceChanged;
  final void Function(String?) onSelectedAttributeChanged;
  final void Function(String?) onSelectedArchetypeChanged;
  final void Function(String?) onSelectedLevelChanged;
  final void Function(String?) onSelectedScaleChanged;
  final void Function(String?) onSelectedLinkRatingChanged;
  final void Function(String?) onSelectedBanlistTCGChanged;
  final void Function(String?) onSelectedBanlistOCGChanged;
  final void Function(String?) onAtkOperatorChanged;
  final void Function(String?) onDefOperatorChanged;
  final void Function(String?) onLevelOperatorChanged;
  final void Function(String?) onScaleOperatorChanged;
  final void Function(String?) onLinkRatingOperatorChanged;
  final VoidCallback performSearch;
  final VoidCallback resetFilters;

  FilterFormView({
    super.key, // Geändert zu super.key (gute Praxis für StatelessWidget)
    required this.types,
    required this.races,
    required this.attributes,
    required this.archetypes,
    required this.banlistStatuses,
    required this.selectedType,
    required this.selectedRace,
    required this.selectedAttribute,
    required this.selectedArchetype,
    required this.selectedLevel,
    required this.selectedScale,
    required this.selectedLinkRating,
    required this.selectedBanlistTCG,
    required this.selectedBanlistOCG,
    required this.atkController,
    required this.defController,
    required this.atkOperator,
    required this.defOperator,
    required this.levelOperator,
    required this.scaleOperator,
    required this.linkRatingOperator,
    required this.onSelectedTypeChanged,
    required this.onSelectedRaceChanged,
    required this.onSelectedAttributeChanged,
    required this.onSelectedArchetypeChanged,
    required this.onSelectedLevelChanged,
    required this.onSelectedScaleChanged,
    required this.onSelectedLinkRatingChanged,
    required this.onSelectedBanlistTCGChanged,
    required this.onSelectedBanlistOCGChanged,
    required this.onAtkOperatorChanged,
    required this.onDefOperatorChanged,
    required this.onLevelOperatorChanged,
    required this.onScaleOperatorChanged,
    required this.onLinkRatingOperatorChanged,
    required this.performSearch,
    required this.resetFilters,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 12.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Grid mit neuen Komponenten
          _buildFilterGrid(spacing),

          SizedBox(height: MediaQuery.of(context).size.height / 40),

          // Suchen/Zurücksetzen Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: performSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGrid(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        FilterDropdown(
          value: selectedType,
          items: types,
          onChanged: onSelectedTypeChanged,
        ),
        SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: FilterDropdown(
                value: selectedRace,
                items: races,
                onChanged: onSelectedRaceChanged,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: FilterDropdown(
                value: selectedAttribute,
                items: attributes,
                onChanged: onSelectedAttributeChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),

        FilterDropdown(
          value: selectedArchetype,
          items: archetypes,
          onChanged: onSelectedArchetypeChanged,
        ),
        SizedBox(height: spacing),

        OperatorDropdown(
          value: selectedLevel,
          items: levelItems,
          operator: levelOperator,
          operators: operators,
          onChanged: onSelectedLevelChanged,
          onOperatorChanged: onLevelOperatorChanged,
        ),
        SizedBox(height: spacing),

        OperatorDropdown(
          value: selectedScale,
          items: scaleItems,
          operator: scaleOperator,
          operators: operators,
          onChanged: onSelectedScaleChanged,
          onOperatorChanged: onScaleOperatorChanged,
        ),
        SizedBox(height: spacing),

        OperatorDropdown(
          value: selectedLinkRating,
          items: linkRatingItems,
          operator: linkRatingOperator,
          operators: operators,
          onChanged: onSelectedLinkRatingChanged,
          onOperatorChanged: onLinkRatingOperatorChanged,
        ),
        SizedBox(height: spacing),

        OperatorTextInput(
          label: 'ATK',
          controller: atkController,
          operator: atkOperator,
          operators: operators,
          onOperatorChanged: onAtkOperatorChanged,
        ),
        SizedBox(height: spacing),

        OperatorTextInput(
          label: 'DEF',
          controller: defController,
          operator: defOperator,
          operators: operators,
          onOperatorChanged: onDefOperatorChanged,
        ),
        SizedBox(height: spacing),

        Row(
          children: [
            Expanded(
              child: FilterDropdown(
                value: selectedBanlistTCG,
                items: banlistStatuses,
                onChanged: onSelectedBanlistTCGChanged,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: FilterDropdown(
                value: selectedBanlistOCG,
                items: banlistStatuses,
                onChanged: onSelectedBanlistOCGChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
