// home.dart

import 'package:flutter/material.dart';
import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';
import 'package:tcg_app/class/common/buildCards.dart';

class Home extends StatefulWidget {
  final Map<String, List<dynamic>>? preloadedTCGBannlist;
  final Map<String, List<dynamic>>? preloadedOCGBannlist;

  const Home({super.key, this.preloadedTCGBannlist, this.preloadedOCGBannlist});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _showTCGBannlist = true;
  bool _showOCGBannlist = false;
  Map<String, dynamic>? _selectedCard;

  final CardData _cardData = CardData();
  late Future<Map<String, List<dynamic>>> _tcgListFuture;
  late Future<Map<String, List<dynamic>>> _ocgListFuture;

  @override
  void initState() {
    super.initState();
    // Nutze vorgeladene Daten wenn verfügbar, sonst lade neu
    if (widget.preloadedTCGBannlist != null) {
      _tcgListFuture = Future.value(widget.preloadedTCGBannlist!);
    } else {
      _tcgListFuture = _cardData.sortTCGBannCards();
    }

    if (widget.preloadedOCGBannlist != null) {
      _ocgListFuture = Future.value(widget.preloadedOCGBannlist!);
    } else {
      _ocgListFuture = _cardData.sortOCGBannCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wenn eine Karte ausgewählt ist, zeige CardDetailView
    if (_selectedCard != null) {
      return CardDetailView(
        cardData: _selectedCard!,
        onBack: () {
          setState(() {
            _selectedCard = null;
          });
        },
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showTCGBannlist = !_showTCGBannlist;
                    _showOCGBannlist = false;
                  });
                },
                child: const Text("TCG Bannlist"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showOCGBannlist = !_showOCGBannlist;
                    _showTCGBannlist = false;
                  });
                },
                child: const Text("OCG Bannlist"),
              ),
            ],
          ),
        ),

        // Die Bannlist(s)
        Expanded(
          child: _showTCGBannlist
              ? _buildBannlistView(_tcgListFuture)
              : _showOCGBannlist
              ? _buildBannlistView(_ocgListFuture)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBannlistView(Future<Map<String, List<dynamic>>> sortedCards) {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: sortedCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              "Fehler: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          final banned = snapshot.data!['banned'] ?? [];
          final limited = snapshot.data!['limited'] ?? [];
          final semiLimited = snapshot.data!['semiLimited'] ?? [];

          return ListView(
            children: [
              if (banned.isNotEmpty) ...[
                _buildSectionHeader('Forbidden'),
                _buildSectionContainer(
                  cards: banned,
                  icon: Icons.cancel,
                  iconText: null,
                ),
              ],
              if (limited.isNotEmpty) ...[
                _buildSectionHeader('Limited'),
                _buildSectionContainer(
                  cards: limited,
                  icon: null,
                  iconText: '1',
                ),
              ],
              if (semiLimited.isNotEmpty) ...[
                _buildSectionHeader('Semi-Limited'),
                _buildSectionContainer(
                  cards: semiLimited,
                  icon: null,
                  iconText: '2',
                ),
              ],
            ],
          );
        } else {
          return const Center(child: Text("Keine Karten gefunden"));
        }
      },
    );
  }

  /// Baut den Container für die Kartenliste
  Widget _buildSectionContainer({
    required List<dynamic> cards,
    IconData? icon,
    String? iconText,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCardItem(card: card, icon: icon, iconText: iconText),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Baut den Sektionstitel
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  /// Baut einen einzelnen Karten-Eintrag
  Widget _buildCardItem({
    required Map<String, dynamic> card,
    IconData? icon,
    String? iconText,
  }) {
    final Future<String> imgPathFuture = _cardData.getImgPath(
      card["card_images"][0]["image_url"],
    );

    const imageSize = 60.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Icon oder Zahl
          icon != null
              ? Icon(icon, size: 12, fontWeight: FontWeight.w100)
              : Text(iconText!, style: TextStyle(fontWeight: FontWeight.bold)),

          // Kartenbild
          FutureBuilder<String>(
            future: imgPathFuture,
            builder: (context, imgSnapshot) {
              if (imgSnapshot.connectionState == ConnectionState.done &&
                  imgSnapshot.hasData &&
                  imgSnapshot.data!.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imgSnapshot.data!,
                    width: imageSize,
                    height: imageSize,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.error, size: 30),
                      );
                    },
                  ),
                );
              }
              return Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Kartenname
          Expanded(
            child: Text(
              card["name"],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
