import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';

class CardData implements Dbrepo {
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

  // Methode für TCG Bannlist
  Future<List<Map<String, dynamic>>> getTCGBannedCards() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .where('banlist_info.ban_tcg', isNull: false)
          .get();

      // Sortiere die Ergebnisse im Code nach Namen
      final cards = snapshot.docs.map((doc) => doc.data()).toList();
      cards.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      return cards;
    } catch (e) {
      print("Fehler beim Abrufen der TCG Karten: $e");
      return [];
    }
  }

  Future<Map<String, List<dynamic>>> sortTCGBannCards() async {
    Future<List<Map<String, dynamic>>> liste = getTCGBannedCards();
    List<dynamic> banned = [];
    List<dynamic> semiLimited = [];
    List<dynamic> limited = [];

    Map<String, List<dynamic>> sortedList = {};

    for (var element in await liste) {
      if (element["banlist_info"]["ban_tcg"] == "Forbidden") {
        banned.add(element);
      }
      if (element["banlist_info"]["ban_tcg"] == "Semi-Limited") {
        semiLimited.add(element);
      }

      if (element["banlist_info"]["ban_tcg"] == "Limited") {
        limited.add(element);
      }
    }

    sortedList["limited"] = limited;
    sortedList["banned"] = banned;
    sortedList["semiLimited"] = semiLimited;
    return sortedList;
  }

  Future<Map<String, List<dynamic>>> sortOCGBannCards() async {
    Future<List<Map<String, dynamic>>> liste = getOCGBannedCards();
    List<dynamic> banned = [];
    List<dynamic> semiLimited = [];
    List<dynamic> limited = [];

    Map<String, List<dynamic>> sortedList = {};

    for (var element in await liste) {
      if (element["banlist_info"]["ban_ocg"] == "Forbidden") {
        banned.add(element);
      }
      if (element["banlist_info"]["ban_ocg"] == "Semi-Limited") {
        semiLimited.add(element);
      }

      if (element["banlist_info"]["ban_ocg"] == "Limited") {
        limited.add(element);
      }
    }

    sortedList["limited"] = limited;
    sortedList["banned"] = banned;
    sortedList["semiLimited"] = semiLimited;
    return sortedList;
  }

  // Methode für OCG Bannlist
  Future<List<Map<String, dynamic>>> getOCGBannedCards() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('cards')
          .where('banlist_info.ban_ocg', isNull: false)
          .get();

      // Sortiere die Ergebnisse im Code nach Namen
      final cards = snapshot.docs.map((doc) => doc.data()).toList();
      cards.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      return cards;
    } catch (e) {
      print("Fehler beim Abrufen der OCG Karten: $e");
      return [];
    }
  }

  // Behalten Sie die alte Methode für Kompatibilität oder löschen Sie sie
  @override
  Future<List<Map<String, dynamic>>> getAllCardsFromBannlist() async {
    // Standardmäßig TCG zurückgeben
    return getTCGBannedCards();
  }

  Future<String> getImgPath(String gsPath) async {
    try {
      final storage = FirebaseStorage.instance;

      // Extrahiere und dekodiere den Pfad
      final uri = Uri.parse(gsPath);
      final path = Uri.decodeComponent(uri.path.substring(1));

      // Verwende ref() mit dem dekodierten Pfad
      final Reference gsReference = storage.ref(path);
      final String downloadUrl = await gsReference.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Fehler ($gsPath): ${e.code} - ${e.message}');
      return '';
    } catch (e) {
      print('Allgemeiner Fehler beim Abrufen der URL für $gsPath: $e');
      return '';
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
