// user_profile_side.dart - AKTUALISIERT FÜR NEUES DECK LAYOUT
import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
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
  bool _showDeckCreation = false;
  String? _editingDeckId;
  final GlobalKey<DeckCreationScreenState> _deckCreationKey = GlobalKey();

  final Userdata userdb = Userdata();
  final authRepo = FirebaseAuthRepository();
  final DeckService _deckService = DeckService();
  final CardData cardData = CardData();
  late Future<Map<String, dynamic>> userData;

  String? email;
  String? uid;

  String? _usernameFromDB;
  bool _isLoadingUsername = true;

  @override
  void initState() {
    super.initState();
    final currentUser = authRepo.getCurrentUser();

    if (currentUser != null) {
      uid = currentUser.uid;
      email = currentUser.email;
      userData = userdb.readUser(uid!);

      _loadUsernameFromFirestore(uid!);
    } else {
      uid = null;
      email = "Gast";
      userData = Future.value({});
      _isLoadingUsername = false;
    }
  }

  Future<void> _loadUsernameFromFirestore(String userId) async {
    final firestore = FirebaseFirestore.instance;
    String? fetchedUsername;

    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        fetchedUsername = doc.data()?['username'] as String?;
      }
    } catch (e) {
      print("Fehler beim Laden des Usernamens: $e");
    }

    if (mounted) {
      setState(() {
        _usernameFromDB = fetchedUsername;
        _isLoadingUsername = false;
      });
    }
  }

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

  int _getDeckCardCount(List<Map<String, dynamic>> deck) {
    return deck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
  }

  Future<void> _handleDeckSave(Map<String, dynamic> deckData) async {
    try {
      _deckCreationKey.currentState?.setSaving(true);

      if (_editingDeckId == null) {
        await _deckService.createDeck(
          deckName: deckData['deckName'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
          coverImageUrl: deckData['coverImageUrl'],
        );
      } else {
        await _deckService.updateDeck(
          deckId: _editingDeckId!,
          deckName: deckData['deckName'],
          description: deckData['description'],
          mainDeck: deckData['mainDeck'],
          extraDeck: deckData['extraDeck'],
          sideDeck: deckData['sideDeck'],
          coverImageUrl: deckData['coverImageUrl'],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deck erfolgreich gespeichert!')),
        );
        setState(() {
          _showDeckCreation = false;
          _editingDeckId = null;
          // Daten neu laden, damit das neue Deck sichtbar ist
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

  void _openDeckForEdit(String deckId) {
    setState(() {
      _editingDeckId = deckId;
      _showDeckCreation = true;
    });
  }

  // ✅ ANGEPASST: Prüft jetzt auch ob in Kartendetail-Ansicht
  Widget _buildDeckCreationView() {
    final isShowingDetail =
        _deckCreationKey.currentState?.isShowingCardDetail ?? false;

    // ✅ WENN in Detail-Ansicht: Zeige NUR DeckCreationScreen (der zeigt dann die Karte)
    if (isShowingDetail) {
      return Expanded(
        child: DeckCreationScreen(
          key: _deckCreationKey,
          initialDeckId: _editingDeckId,
          onDataCollected: (data) {},
          onDetailViewChanged: (isShowing) {
            setState(() {
              // State wird automatisch aktualisiert
            });
          },
          onCancel: () {
            setState(() {
              _showDeckCreation = false;
              _editingDeckId = null;
              userData = userdb.readUser(uid!);
            });
          },
          onSaved: () {
            setState(() {
              _showDeckCreation = false;
              _editingDeckId = null;
              userData = userdb.readUser(uid!);
            });
          },
        ),
      );
    }

    // ✅ SONST: Zeige normale Ansicht mit Buttons
    return Column(
      children: [
        // Zurück-Button und Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _showDeckCreation = false;
                      _editingDeckId = null;
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingDeckId != null
                            ? 'Deck bearbeiten'
                            : 'Neues Deck erstellen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text('Klicke auf eine Karte für Details'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // DeckCreationScreen
        Expanded(
          child: DeckCreationScreen(
            key: _deckCreationKey,
            initialDeckId: _editingDeckId,
            onDataCollected: (data) {},
            onDetailViewChanged: (isShowing) {
              setState(() {
                // State wird automatisch aktualisiert
              });
            },
            onCancel: () {
              setState(() {
                _showDeckCreation = false;
                _editingDeckId = null;
                userData = userdb.readUser(uid!);
              });
            },
            onSaved: () {
              setState(() {
                _showDeckCreation = false;
                _editingDeckId = null;
                userData = userdb.readUser(uid!);
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeckDelete(String deckId, String deckName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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

  Widget _buildDeckList(Map<String, dynamic> userMap) {
    final List<dynamic> dynamicDecks = userMap['decks'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> decks = dynamicDecks
        .whereType<Map<String, dynamic>>()
        .toList();

    final String deckCreator = _usernameFromDB!;

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
        final mainDeckData = deck['mainDeck'] as List<dynamic>? ?? [];
        final mainDeckList = mainDeckData
            .whereType<Map<String, dynamic>>()
            .toList();
        final cardCount = _getDeckCardCount(mainDeckList);
        final deckId = deck['deckId'] as String?;
        final deckName = deck['deckName'] as String;
        final String coverImage = deck["coverImageUrl"] as String? ?? '';

        Future<String?> imgpathFuture = cardData
            .getCorrectImgPath([coverImage])
            .then((result) {
              return result;
            });

        return FutureBuilder<String?>(
          future: imgpathFuture,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (asyncSnapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Center(
                  child: Text(
                    "Fehler beim Laden des Bildes: ${asyncSnapshot.error}",
                  ),
                ),
              );
            }

            final String? imageUrl = asyncSnapshot.data;

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Image.network(
                                  imageUrl,
                                  width: 50,
                                  height: 50,
                                ),
                              ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (deckName.isNotEmpty)
                                  Text(
                                    "$deckName ($cardCount Karten)",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),

                                Text(deckCreator),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.edit, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              if (deckId != null) {
                                _handleDeckDelete(deckId, deckName);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.delete, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> userMap) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Willkommen, ${_usernameFromDB ?? email ?? "unbekannt"}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _editingDeckId = null;
                  _showDeckCreation = true;
                });
              },
              child: const Text('Neues Deck erstellen'),
            ),
            const SizedBox(height: 24),
            Text('Deine Decks'),
            const SizedBox(height: 16),
            _buildDeckList(userMap),
            const SizedBox(height: 24),
            Text('Account-Einstellungen'),
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

        if (_showDeckCreation) {
          return _buildDeckCreationView();
        } else {
          return _buildProfileContent(userMap);
        }
      },
    );
  }
}
