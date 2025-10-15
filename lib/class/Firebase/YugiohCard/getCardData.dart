import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcg_app/class/Firebase/interfaces/dbRepo.dart';

class getChardData implements Dbrepo {
  getBanInfos() {}

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
  Future<dynamic> getAllCardsFromBannlist() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('cards')
        .where('banlist', isNotEqualTo: null)
        .get();

    return querySnapshot;
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
