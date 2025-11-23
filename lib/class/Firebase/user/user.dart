// lib/class/Firebase/user/user.dart

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

      final decksSnapshot = await FirebaseFirestore.instance
          .collection('decks')
          .where('userId', isEqualTo: userId)
          .get();

      data['decks'] = decksSnapshot.docs.map((doc) => doc.data()).toList();

      return data;
    } else {
      return {};
    }
  }

  Future<void> deleteUser(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      throw Exception("User not found");
    }

    await userDoc.delete();
  }

  /// ✅ NEUE METHODE: Reauthentication
  Future<void> reauthenticateUser(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No User is logged in");
    }

    if (user.email == null) {
      throw Exception("Bthe user has no Email adress");
    }

    // Erstelle Credentials mit aktueller E-Mail und Passwort
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    // Reauthenticate
    await user.reauthenticateWithCredential(credential);
    print("✅pls authenticate again");
  }

  /// ✅ KORRIGIERTE METHODE: Erfordert Passwort-Eingabe
  Future<void> deleteUserCompletely(String userId, String password) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.uid != userId) {
        throw Exception("not authenticated");
      }

      // 🔐 SCHRITT 1: REAUTHENTICATION
      print("🔐 authentication has started again...");
      await reauthenticateUser(password);

      // 🗑️ SCHRITT 2: Lösche alle Decks
      final decksSnapshot = await firestore
          .collection('decks')
          .where('userId', isEqualTo: userId)
          .get();

      print('🗑️ Lösche ${decksSnapshot.docs.length} Decks...');

      await Future.wait(
        decksSnapshot.docs.map((deckDoc) async {
          final deckId = deckDoc.id;

          // Lösche alle Kommentare
          final commentsSnapshot = await firestore
              .collection('decks')
              .doc(deckId)
              .collection('comments')
              .get();

          if (commentsSnapshot.docs.isNotEmpty) {
            final batch = firestore.batch();
            for (var commentDoc in commentsSnapshot.docs) {
              batch.delete(commentDoc.reference);
            }
            await batch.commit();
            print('  ↳ ${commentsSnapshot.docs.length} Kommentare gelöscht');
          }

          await deckDoc.reference.delete();
          print('  ↳ Deck "$deckId" gelöscht');
        }),
      );

      // 🗑️ SCHRITT 3: Lösche das User-Dokument
      await deleteUser(userId);
      print('✅ User-Dokument gelöscht');

      // 🗑️ SCHRITT 4: Lösche den Firebase Auth Account
      await currentUser.delete();
      print('✅ Firebase Auth Account gelöscht');

      print('🎉 User $userId wurde komplett gelöscht!');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Fehler: ${e.code}');

      if (e.code == 'wrong-password') {
        throw Exception('wrong password');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('pls login again');
      } else {
        throw Exception('Authentifizierungsfehler: ${e.message}');
      }
    } catch (e) {
      print('❌ Fehler beim Löschen des Users: $e');
      rethrow;
    }
  }

  @override
  Future<void> getAllCardsFromBannlist() {
    throw UnimplementedError();
  }
}
