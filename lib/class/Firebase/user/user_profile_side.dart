import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tcg_app/class/widgets/deckservice.dart';
import 'package:tcg_app/providers/app_providers.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
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
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _showDeckCreation = false;
  String? _editingDeckId;
  final GlobalKey<DeckCreationScreenState> _deckCreationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully logged out!")),
        );
        widget.onItemTapped(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error on logout: $e")));
      }
    }
  }

  // In lib/class/Firebase/user/user_profile_side.dart

  Future<void> _showDeleteUserConfirmation() async {
    final TextEditingController passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you really want to permanently delete your account?\n\nThis action cannot be undone and all your data will be permanently deleted.',
              ),
              const SizedBox(height: 16),
              // 🔐 PASSWORT-EINGABE
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm with password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your password')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirm == true && passwordController.text.trim().isNotEmpty) {
      await _deleteUser(passwordController.text.trim());
    }

    passwordController.dispose();
  }

  Future<void> _deleteUser(String password) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final userdata = ref.read(userdataProvider);

      // ✅ ÜBERGEBE PASSWORT
      await userdata.deleteUserCompletely(currentUser.uid, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account successfully deleted!")),
        );
        widget.onItemTapped(0);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error deleting account: ${e.toString().replaceFirst('Exception: ', '')}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  int _getDeckCardCount(List<Map<String, dynamic>> deck) {
    return deck.fold(0, (sum, card) => sum + (card['count'] as int? ?? 0));
  }

  void _openDeckForEdit(String deckId) {
    setState(() {
      _editingDeckId = deckId;
      _showDeckCreation = true;
    });
  }

  Widget _buildDeckCreationView() {
    return Column(
      children: [
        Expanded(
          child: DeckCreationScreen(
            key: _deckCreationKey,
            initialDeckId: _editingDeckId,
            onDataCollected: (data) {},
            onDetailViewChanged: (isShowing) {
              setState(() {});
            },
            onCancel: () {
              setState(() {
                _showDeckCreation = false;
                _editingDeckId = null;
              });
              ref.invalidate(userDataProvider);
            },
            onSaved: () {
              setState(() {
                _showDeckCreation = false;
                _editingDeckId = null;
              });
              ref.invalidate(userDataProvider);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteDeckConfirmation(
    String deckId,
    String deckName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Deck'),
          content: Text(
            'Do you really want to delete the deck "$deckName"?\n\nThis action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _handleDeckDelete(deckId, deckName);
    }
  }

  Future<void> _handleDeckDelete(String deckId, String deckName) async {
    try {
      final deckService = ref.read(deckServiceProvider);
      await deckService.deleteDeck(deckId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$deckName" successfully deleted!')),
        );
        ref.invalidate(userDataProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting deck: $e')));
      }
    }
  }

  Widget _buildDeckList(Map<String, dynamic> userMap, String username) {
    final cardData = ref.watch(cardDataProvider);

    final List<dynamic> dynamicDecks = userMap['decks'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> decks = dynamicDecks
        .whereType<Map<String, dynamic>>()
        .toList();

    if (decks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('You haven\'t created a deck yet'),
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
        final extraDeckData = deck['extraDeck'] as List<dynamic>? ?? [];

        final mainDeckList = mainDeckData
            .whereType<Map<String, dynamic>>()
            .toList();
        final extraDeckList = extraDeckData
            .whereType<Map<String, dynamic>>()
            .toList();

        final mainCardCount = _getDeckCardCount(mainDeckList);

        final totalCardCount = mainCardCount;

        final deckId = deck['deckId'] as String?;
        final deckName = deck['deckName'] as String;
        final String coverImage = deck["coverImageUrl"] as String? ?? '';

        // Get the actual username from the deck, if available
        final deckUsername = deck['username'] as String? ?? username;

        return FutureBuilder<String?>(
          future: cardData.getCorrectImgPath([coverImage]),
          builder: (context, imageSnapshot) {
            final String? imageUrl = imageSnapshot.data;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Deck Cover Image
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.style),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: const Icon(Icons.style),
                      ),

                    // Deck Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deckName),
                          const SizedBox(height: 4),
                          Text('$totalCardCount Cards • by $deckUsername'),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (deckId != null) {
                              _openDeckForEdit(deckId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Deck ID missing! Editing not possible',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Deck',
                        ),
                        IconButton(
                          onPressed: () {
                            if (deckId != null) {
                              _showDeleteDeckConfirmation(deckId, deckName);
                            }
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Deck',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> userMap, String username) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $username'),
                  const SizedBox(height: 24),

                  // Create Deck Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _editingDeckId = null;
                        _showDeckCreation = true;
                      });
                    },
                    child: const Text('Create New Deck'),
                  ),
                  const SizedBox(height: 24),

                  // Your Decks Section
                  const Text('Your Decks'),
                  const SizedBox(height: 16),
                  _buildDeckList(userMap, username),
                ],
              ),
            ),
          ),
        ),

        // Account Settings Section - AT THE BOTTOM OF THE SCREEN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Settings'),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Logout Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete Account Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteUserConfirmation,
                      icon: const Icon(Icons.delete_forever, size: 20),
                      label: const Text("Delete Account"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Center(child: Text('Not logged in'));
    }

    final userDataAsync = ref.watch(userDataProvider(currentUser.uid));
    final usernameAsync = ref.watch(usernameProvider(currentUser.uid));

    if (_showDeckCreation) {
      return _buildDeckCreationView();
    }

    return userDataAsync.when(
      data: (userMap) {
        return usernameAsync.when(
          data: (username) => _buildProfileContent(userMap, username),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildProfileContent(userMap, 'User'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
