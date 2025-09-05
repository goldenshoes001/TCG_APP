import 'package:flutter/material.dart';

class YugiohKarte {
  static const List<String> _cardTypes = ["monster", "spell", "trap"];

  final int idNumber;
  final String name;
  final String cardType;
  final List<String> archetype;
  final String imagePath;

  YugiohKarte({
    required this.idNumber,
    required this.name,
    required String cardType,
    required this.archetype,
    required this.imagePath,
  }) : cardType = _cardTypes.contains(cardType.toLowerCase())
           ? cardType
           : throw ArgumentError(
               'Ungültiger Kartentyp: "$cardType". Gültige Typen sind: ${_cardTypes.join(', ')}.',
             );
}
