import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:tcg_app/class/kommentar.dart';
import 'package:tcg_app/class/user.dart';
import 'package:tcg_app/class/yugiohkarte.dart'; 

class DatabaseRepository {
  int showYugiohKarteID(YugiohKarte card) {
    return 0;
  }

  YugiohKarte findYugiohKarte(int id) {
    return YugiohKarte(idNumber: 0, name: '', cardType: '', archetype: '', imagePath: "");
  }

  void deleteYugiohKarte(int id) {}

  User erstelleNutzer() {
    return User();
  }

  User leseNutzerDaten() {
    return User();
  }

  User updateNutzer() {
    return User();
  }

  void deleteNutzer() {}

  Kommentar findeKommentar() {
    return Kommentar();
  }

  Kommentar erstelleKommentar() {
    return Kommentar();
  }

  void updateKommentar() {}

  void deleteKommentar() {}

  List<Kommentar> bekommeAlleKommentare() {
    List<Kommentar> liste = [];

    return liste;
  }
}
