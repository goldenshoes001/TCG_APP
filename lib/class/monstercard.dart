

import 'package:tcg_app/class/yugiohkarte.dart';

class Monstercard extends YugiohKarte {
  final String attribute;
  final String type;
  final int level;
  final int atk;
  final int? def; // Nullable für Link Monster
  final String deckType;
  final String subtype;
  final String cardText;

  Monstercard({required super.imagePath,
    required super.archetype,
    required super.idNumber,
    required super.name,
    required super.cardType,
    required this.attribute,
    required this.type,
    required this.level,
    required this.atk,
    this.def,
    required this.deckType,
    required this.subtype,
    required this.cardText, 
  });
}
