import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';

class Userdata implements Dbrepo {
  static Userdata? _instance;

  Userdata._internal();

  factory Userdata() {
    _instance ??= Userdata._internal();

    return _instance!;
  }

  @override
  Future<void> createDeck() {
    throw UnimplementedError();
  }

  @override
  Future<void> createUser(String username, String email, String userId) async {
    final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);
    await userDoc.set({"username": username, "email": email, "userId": userId});
  }

  @override
  Future<void> readDeck() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> readUser(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);
    DocumentSnapshot<Map<String, dynamic>> snapshot = await userDoc.get();

    if (snapshot.exists) {
      final Map<String, dynamic> data = snapshot.data()!;

      // *** FEHLENDER SCHRITT: Decks abrufen ***
      // Holen Sie die Decks aus der 'decks'-Collection, die zu dieser 'userId' gehören
      final decksSnapshot = await FirebaseFirestore.instance
          .collection('decks')
          .where('userId', isEqualTo: userId)
          .get();

      // Fügen Sie die Deck-Daten der Benutzer-Map hinzu (als Liste)
      data['decks'] = decksSnapshot.docs.map((doc) => doc.data()).toList();

      return data;
    } else {
      return {};
    }
  }

  Future<void> deleteUser(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);

    // Prüfen ob Dokument existiert
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      throw Exception("Benutzer nicht gefunden");
    }

    await userDoc.delete();
  }

  Future<void> deleteUserCompletely(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Finde alle Decks des Nutzers
      final decksSnapshot = await firestore
          .collection('decks')
          .where('userId', isEqualTo: userId)
          .get();

      print('🗑️ Lösche ${decksSnapshot.docs.length} Decks...');

      // 2. Lösche alle Decks mit ihren Kommentaren (parallel für bessere Performance)
      await Future.wait(
        decksSnapshot.docs.map((deckDoc) async {
          final deckId = deckDoc.id;

          // Lösche alle Kommentare
          final commentsSnapshot = await firestore
              .collection('decks')
              .doc(deckId)
              .collection('comments')
              .get();

          // Batch-Delete für bessere Performance
          if (commentsSnapshot.docs.isNotEmpty) {
            final batch = firestore.batch();
            for (var commentDoc in commentsSnapshot.docs) {
              batch.delete(commentDoc.reference);
            }
            await batch.commit();
            print('  ↳ ${commentsSnapshot.docs.length} Kommentare gelöscht');
          }

          // Lösche das Deck
          await deckDoc.reference.delete();
          print('  ↳ Deck "$deckId" gelöscht');
        }),
      );

      // 3. Lösche das User-Dokument
      await deleteUser(userId);
      print('✅ User-Dokument gelöscht');

      // 4. Lösche den Firebase Auth Account
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
        print('✅ Firebase Auth Account gelöscht');
      }

      print('🎉 User $userId wurde komplett gelöscht!');
    } catch (e) {
      print('❌ Fehler beim Löschen des Users: $e');
      rethrow;
    }
  }

  @override
  Future<void> getAllCardsFromBannlist() {
    // TODO: implement getAllCardsFromBannlist
    throw UnimplementedError();
  }
}
