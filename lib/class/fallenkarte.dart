
import 'package:tcg_app/class/yugiohkarte.dart';

class Fallenkarte extends YugiohKarte {
  final String fallenTyp;
  final String text;

  Fallenkarte({
    required super.imagePath,
    required super.idNumber,
    required super.name,
    required super.cardType,
    required this.fallenTyp,
    required this.text,
    required super.archetype, 
  });
}
