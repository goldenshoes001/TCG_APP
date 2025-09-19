import 'package:tcg_app/class/kommentar.dart';
import 'package:tcg_app/class/user.dart';
import 'package:tcg_app/class/yugiohkarte.dart';

abstract class DatabaseRepository {
  Future<List<YugiohKarte>> getallCards();

  Future<User> erstelleNutzer();
  Future<User> leseNutzerDaten();
  Future<User> updateNutzer();
  Future<void> deleteNutzer();

  Future<Kommentar> findeKommentar();
  Future<Kommentar> erstelleKommentar();
  Future<void> updateKommentar();
  Future<void> deleteKommentar();

  Future<List<Kommentar>> bekommeAlleKommentare();
}
