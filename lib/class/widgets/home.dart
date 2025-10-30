// home.dart

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/widgets/helperClass/SortedCardList.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _showTCGBannlist = true;
  bool _showOCGBannlist = false;
  bool _isCardSelected = false; // Neuer State für Kartenauswahl

  final Future<Map<String, List<dynamic>>> TCGList = CardData()
      .sortTCGBannCards();
  final Future<Map<String, List<dynamic>>> OCGList = CardData()
      .sortOCGBannCards();

  void _onCardSelectionChanged(bool isSelected) {
    setState(() {
      _isCardSelected = isSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons nur anzeigen, wenn keine Karte ausgewählt ist
        if (!_isCardSelected)
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showTCGBannlist = !_showTCGBannlist;
                    _showOCGBannlist = false;
                  });
                },
                child: const Text("TCG Bannlist"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showOCGBannlist = !_showOCGBannlist;
                    _showTCGBannlist = false;
                  });
                },
                child: const Text("OCG Bannist"),
              ),
            ],
          ),
        // Die Bannlist(s)
        if (_showTCGBannlist)
          Expanded(
            child: sortedCardList(
              sortedCards: TCGList,
              onCardSelectionChanged: _onCardSelectionChanged,
            ),
          ),
        if (_showOCGBannlist)
          Expanded(
            child: sortedCardList(
              sortedCards: OCGList,
              onCardSelectionChanged: _onCardSelectionChanged,
            ),
          ),
      ],
    );
  }
}
