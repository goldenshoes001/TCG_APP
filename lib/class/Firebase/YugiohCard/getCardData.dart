import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';

class getChardData implements Dbrepo {
  getBanInfos() {}
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Wichtig: Die Methode muss 'async' sein und 'Future<List<Map<String, dynamic>>>' zurückgeben,
  // da sie Dokumente abruft, die Maps sind.
  Future<List<Map<String, dynamic>>> getallChards() async {
    try {
      // 1. Holen Sie die Referenz zur 'cards' Collection.
      // 2. Rufen Sie .get() auf, um die Abfrage auszuführen (asynchron).
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .limit(50)
          .get();

      // 3. Verwenden Sie .docs, um die Liste der Dokumente zu erhalten.
      // 4. Verwenden Sie .map((doc) => doc.data()) und .toList(), um die Dokument-Snapshots
      //    in eine saubere Liste von Maps umzuwandeln (reine Daten).
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Fehlerbehandlung: Wichtig bei Datenbankzugriffen
      print("Fehler beim Abrufen der Karten: $e");
      // Geben Sie bei einem Fehler eine leere Liste zurück
      return [];
    }
  }

  @override
  Future<void> createDeck() {
    // TODO: implement createDeck
    throw UnimplementedError();
  }

  @override
  Future<void> createUser(String username, String email, String userId) {
    // TODO: implement createUser
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllCardsFromBannlist() async {
    try {
      // 1. Holen Sie die Referenz zur 'cards' Collection.
      // 2. Rufen Sie .get() auf, um die Abfrage auszuführen (asynchron).
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          // 1. Filter: Zeige nur Karten, die in der TCG-Banliste sind
          .where('banlist_info.ban_tcg', isNull: false)
          // 2. Sortierung: Sortiere die Ergebnisse alphabetisch nach dem Feld 'name'
          .orderBy('name')
          .get();

      // 3. Verwenden Sie .docs, um die Liste der Dokumente zu erhalten.
      // 4. Verwenden Sie .map((doc) => doc.data()) und .toList(), um die Dokument-Snapshots
      //    in eine saubere Liste von Maps umzuwandeln (reine Daten).
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Fehlerbehandlung: Wichtig bei Datenbankzugriffen
      print("Fehler beim Abrufen der Karten: $e");
      // Geben Sie bei einem Fehler eine leere Liste zurück
      return [];
    }
  }

  @override
  Future<void> readDeck() {
    // TODO: implement readDeck
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> readUser(String userId) {
    // TODO: implement readUser
    throw UnimplementedError();
  }
}
