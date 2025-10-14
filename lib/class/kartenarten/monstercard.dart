import 'package:tcg_app/class/kartenarten/yugiohkarte.dart';

class Monstercard extends YugiohKarte {
  int atk;
  int def;
  int level;
  int race;
  int attribute;
  Monstercard({
    required super.hasEffect,
    required super.idNumber,
    required super.name,
    required super.type,
    required super.frameType,
    required super.desc,
    required super.imagePath,
    required this.atk,
    required this.def,
    required this.level,
    required this.race,
    required this.attribute
  });
}
