// ============================================================================
// user_profile_side.dart - KOMPLETT ÜBERARBEITET
// ============================================================================

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/interfaces/FirebaseAuthRepository.dart';
import 'package:tcg_app/class/Firebase/user/user.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Function(bool) onThemeChanged;

  const UserProfileScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onThemeChanged,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // NEU: Zustand zur Steuerung der angezeigten Seite
  bool _showDeckCreation = false;

  // NEU: Speichert die ID des zu bearbeitenden Decks (null für Erstellung)
  String? _editingDeckId;

  // GlobalKey für den Zugriff auf die Methoden des Kind-Widgets
  final GlobalKey<DeckCreationScreenState> _deckCreationKey = GlobalKey();

  final Userdata userdb = Userdata();
  final authRepo = FirebaseAuthRepository();
  final DeckService _deckService = DeckService();
  late Future<Map<String, dynamic>> userData;

  String? email;
  String? uid;

  @override
  void initState() {
    super.initState();
    final currentUser = authRepo.getCurrentUser();

    if (currentUser != null) {
      uid = currentUser.uid;
      email = currentUser.displayName ?? currentUser.email;
      userData = userdb.readUser(uid!);
    } else {
      uid = null;
      email = "Gast";
      userData = Future.value({}); // Leere Map als Fallback
    }
  }

  void _saveDeck() {
    // 1. Ruft die Validierung und Datensammlung im Kind-Widget auf
    final deckData = _deckCreationKey.currentState
        ?.collectDeckDataAndValidate();

    // 2. WICHTIG: Prüft, ob die Daten gesammelt (und validiert) wurden
    if (deckData != null) {
      // 3. Wenn die Validierung erfolgreich war, starte den Speichervorgang
      _handleDeckSave(deckData);
    }
  }

  // Logik für Abmeldung
  Future<void> _handleLogout() async {
    try {
      await authRepo.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erfolgreich abgemeldet!")),
        );
        widget.onItemTapped(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Fehler beim Abmelden: $e")));
      }
    }
  }

  // Logik für Benutzer löschen
  Future<void> _deleteUser() async {
    final currentUid = uid;
    if (currentUid == null) return;

    try {
      await userdb.deleteUserCompletely(currentUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account erfolgreich gelöscht!")),
        );
        widget.onItemTapped(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Fehler beim Löschen: $e")));
      }
    }
  }

  // Hilfsfunktion zum Zählen der Karten
  // Nimmt List<Map<String, dynamic>> entgegen
  int _getDeckCardCount(List<Map<String, dynamic>> deck) {
    return deck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
  }

  // Logik für den eigentlichen Speichervorgang in Firestore

  Future<void> _handleDeckSave(Map<String, dynamic> deckData) async {
    try {
      _deckCreationKey.currentState?.setSaving(true);

      // Logik, um zwischen Erstellen und Bearbeiten zu unterscheiden
      if (_editingDeckId == null) {
        // ERSTELLEN
        await _deckService.createDeck(
          deckName: deckData['deckName'],
          archetype: deckData['archetype'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
        );
      } else {
        // *** HIER: IMPLEMENTIERUNG DER BEARBEITUNG ***
        await _deckService.updateDeck(
          deckId: _editingDeckId!, // Die ID des zu bearbeitenden Decks
          deckName: deckData['deckName'],
          archetype: deckData['archetype'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
        );
      }

      // Nach dem Speichern zur Profil-Ansicht zurückkehren
      if (mounted) {
        setState(() {
          _showDeckCreation = false;
          _editingDeckId = null; // ID zurücksetzen
          // *** WICHTIG: Benutzerdaten neu laden, um die aktualisierte Liste anzuzeigen ***
          userData = userdb.readUser(uid!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
      }
    } finally {
      _deckCreationKey.currentState?.setSaving(false);
    }
  }

  // NEU: Methode zum Öffnen eines bestehenden Decks
  void _openDeckForEdit(String deckId) {
    setState(() {
      _editingDeckId = deckId;
      _showDeckCreation = true; // Umschalten zur Bearbeitungsansicht
    });
  }

  // NEU: Methode zum Bauen der Deck-Erstellungs-Ansicht (Header + Body)
  Widget _buildDeckCreationView() {
    return Column(
      children: [
        // KORRIGIERTE KOPFZEILE (Simuliert AppBar)
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 8.0,
            bottom: 8.0,
          ),
          child: Row(
            children: [
              Text(
                _editingDeckId == null ? 'Neues Deck' : 'Deck bearbeiten',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              // ABBRECHEN-Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDeckCreation = false; // Zurück zur Profilansicht
                    _editingDeckId = null; // ID zurücksetzen
                  });
                },
                child: const Text('Abbrechen'),
              ),
              const SizedBox(width: 8),
              // SPEICHERN-Button
              ElevatedButton(
                onPressed: () {
                  // Ruft die öffentliche Methode im Kind-Widget auf

                  _saveDeck();
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
        ),

        // EINGEBETTETER DECK CREATION SCREEN (Body)
        Expanded(
          child: DeckCreationScreen(
            key: _deckCreationKey,
            initialDeckId:
                _editingDeckId, // Hier wird die ID (oder null) übergeben
            onDataCollected: (data) {},
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeckDelete(String deckId, String deckName) async {
    // 1. Bestätigungsdialog anzeigen
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Deck löschen'),
          content: Text(
            'Sind Sie sicher, dass Sie das Deck "$deckName" unwiderruflich löschen möchten?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _deckService.deleteDeck(deckId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deck "$deckName" erfolgreich gelöscht!')),
          );
          // Deck-Liste neu laden, um das gelöschte Deck zu entfernen
          setState(() {
            userData = userdb.readUser(uid!);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen des Decks: $e')),
          );
        }
      }
    }
  }

  // Methode für die Deck-Listen-Anzeige (Korrigierter Typ-Fehler)
  Widget _buildDeckList(Map<String, dynamic> userMap) {
    // Sicherer Abruf: Holen Sie die Liste als List<dynamic>
    final List<dynamic> dynamicDecks = userMap['decks'] as List<dynamic>? ?? [];

    // Konvertieren Sie jeden Eintrag sicher in den erwarteten Typ Map<String, dynamic>
    final List<Map<String, dynamic>> decks = dynamicDecks
        .whereType<Map<String, dynamic>>()
        .toList();

    if (decks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Du hast noch keine Decks erstellt.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];

        // Innere Listen-Konvertierung muss ebenfalls sicher sein!
        final mainDeckData = deck['mainDeck'] as List<dynamic>? ?? [];
        final mainDeckList = mainDeckData
            .whereType<Map<String, dynamic>>()
            .toList();

        final cardCount = _getDeckCardCount(mainDeckList);
        final deckId = deck['deckId'] as String?;
        final deckName = deck['deckName'] as String;
        final archetype = deck['archetype'] as String?;

        return Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(12.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deckName != null && deckName.isNotEmpty)
                      Text(
                        "Deckname: $deckName",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                    if (archetype != null && archetype.isNotEmpty)
                      Text(
                        'Archetyp: $archetype',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),

              // INNERE ROW ZUR ABSTANDSKONTROLLE MIT INKWELLS
              Row(
                mainAxisSize:
                    MainAxisSize.min, // Nimmt nur den benötigten Platz ein
                children: [
                  Text('${cardCount} Karten'),
                  const SizedBox(width: 128),
                  // Abstand zum Text (Kartenanzahl)
                  // 1. BEARBEITEN-ICON mit InkWell
                  InkWell(
                    onTap: () {
                      if (deckId != null) {
                        _openDeckForEdit(deckId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Deck ID fehlt! Bearbeitung nicht möglich.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Icon(Icons.edit, color: Colors.blue),
                  ),

                  // 2. LÖSCHEN-ICON mit InkWell
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (deckId != null) {
                        _handleDeckDelete(deckId, deckName!);
                      }
                    },
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Methode für die Standard-Profilansicht
  Widget _buildProfileContent(Map<String, dynamic> userMap) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Benutzerinformationen
            Text(
              'Willkommen, ${userMap['username'] ?? email}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Button zum Umschalten zum Deck-Erstellen-Screen
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _editingDeckId = null; // WICHTIG: null für neues Deck setzen
                  _showDeckCreation = true;
                });
              },
              child: const Text('Neues Deck erstellen'),
            ),
            const SizedBox(height: 24),

            // Deck-Liste
            Text('Deine Decks', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            _buildDeckList(userMap), // Der korrigierte Listen-Aufruf
            const SizedBox(height: 24),

            // Account-Einstellungen
            Text(
              'Account-Einstellungen',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Abmelden"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _deleteUser,
              icon: const Icon(Icons.delete_forever),
              label: const Text("Account löschen"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        final userMap = snapshot.data ?? {};

        // KONDITIONALE RÜCKGABE
        if (_showDeckCreation) {
          // Zeigt den Header und das Formular
          return _buildDeckCreationView();
        } else {
          // Zeigt die Profilansicht
          return _buildProfileContent(userMap);
        }
      },
    );
  }
}
