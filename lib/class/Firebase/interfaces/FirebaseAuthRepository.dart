


import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/Firebase/interfaces/authrepo.dart';

/// Eine Singleton-Klasse zur Kapselung aller Firebase-Authentifizierungslogiken.
/// Dies stellt sicher, dass es nur eine einzige Instanz im gesamten App-Lebenszyklus gibt.
class FirebaseAuthRepository implements AuthRepository {
  // Eine private, statische Instanz, die die einzige des Singletons sein wird.
  static final FirebaseAuthRepository _instance =
      FirebaseAuthRepository._internal();

  // Ein privater Konstruktor, der die Instanziierung der Klasse von außen verhindert.
  FirebaseAuthRepository._internal();

  // Der öffentliche Factory-Konstruktor, der immer die einzige Instanz _instance zurückgibt.
  factory FirebaseAuthRepository() {
    return _instance;
  }

  /// Meldet einen Benutzer mit E-Mail und Passwort an.
  /// Fängt spezifische Fehler wie 'user-not-found' oder 'wrong-password' ab.
  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Kein Benutzer gefunden für diese E-Mail.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Falsches Passwort.');
      }
      throw Exception('Fehler bei der Anmeldung: ${e.message}');
    }
  }

  /// Erstellt einen neuen Benutzer mit E-Mail und Passwort.
  @override
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Das Passwort ist zu schwach.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Ein Konto für diese E-Mail existiert bereits.');
      }
      throw Exception('Fehler bei der Registrierung: ${e.message}');
    }
  }

  /// Meldet den aktuell angemeldeten Benutzer ab.
  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  /// Gibt einen Stream zurück, der über Änderungen im Authentifizierungsstatus informiert.
  /// (z.B. wenn sich ein Benutzer an- oder abmeldet).
  @override
  Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }

  /// Gibt das User-Objekt des aktuell angemeldeten Benutzers zurück.
  /// Kann null sein, wenn kein Benutzer angemeldet ist.
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
