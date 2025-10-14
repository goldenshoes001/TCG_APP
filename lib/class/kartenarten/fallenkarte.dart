import 'package:tcg_app/class/kartenarten/yugiohkarte.dart';

class Fallenkarte extends YugiohKarte {
  final String race;

  Fallenkarte(
    this.race, {
    required super.imagePath,
    required super.idNumber,
    required super.name,
    required super.hasEffect,
    required super.type,
    required super.frameType,
    required super.desc,
  });
}
