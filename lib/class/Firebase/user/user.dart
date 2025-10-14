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
      return snapshot.data()!;
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
   
    await deleteUser(userId);
    
  
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      await currentUser.delete();
    }
  }
}

