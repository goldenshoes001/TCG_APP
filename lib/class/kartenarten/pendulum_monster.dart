import 'package:tcg_app/class/kartenarten/monstercard.dart';

class Pendulummonster extends Monstercard {
  int scale;
  Pendulummonster({
    required super.hasEffect,
    required super.idNumber,
    required super.name,
    required super.type,
    required super.frameType,
    required super.desc,
    required super.imagePath,
    required super.atk,
    required super.def,
    required super.level,
    required super.race,
    required super.attribute,
    required this.scale  });
}
