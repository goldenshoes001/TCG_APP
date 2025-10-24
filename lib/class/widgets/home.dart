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
  final Future<Map<String, List<dynamic>>> TCGList = CardData()
      .sortTCGBannCards();
  final Future<Map<String, List<dynamic>>> OCGList = CardData()
      .sortTCGBannCards();
  @override
  Widget build(BuildContext context) {
    return Column(
      // Besser: Column statt Row für vertikales Layout
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons in einer Row
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
              child: const Text("OCG Bannlist"),
            ),
          ],
        ),
        // Die Bannlist(s)
        if (_showTCGBannlist)
          Expanded(child: sortedCardList(sortedCards: TCGList)),
        if (_showOCGBannlist)
          Expanded(child: sortedCardList(sortedCards: OCGList)),
      ],
    );
  }
}
