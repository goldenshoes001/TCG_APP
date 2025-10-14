import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/kartenarten/yugiohkarte.dart';
import 'package:tcg_app/class/kommentar.dart';



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
