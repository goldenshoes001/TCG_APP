abstract class Dbrepo {
  Future<void> createUser(String username, String email, String userId);
  Future<Map<String, dynamic>> readUser(String userId);
  Future<void> createDeck();
  Future<void> readDeck();
  Future<void> getAllCardsFromBannlist();
}
