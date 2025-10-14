import 'package:tcg_app/class/kartenarten/yugiohkarte.dart';

class Zauberkarte extends YugiohKarte {
  String race;
  Zauberkarte({
    required super.name,
    required super.imagePath,
    required super.idNumber,
    required super.hasEffect,
    required super.type,
    required super.frameType,
    required super.desc,
    required this.race
  });
}
