import 'package:tcg_app/class/yugiohkarte.dart';

class Zauberkarte extends YugiohKarte {
  final String spellcardType;
  final String text;

  Zauberkarte({
    required super.name,
    required super.imagePath,
    required super.archetype,
    required super.idNumber,
    required super.cardType,

    required this.spellcardType,
    required this.text,
  });
}
