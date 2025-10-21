import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:tcg_app/class/Firebase/YugiohCard/getCardData.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

Future<String> getImgPath(String gsPath) async {
  if (gsPath.isEmpty) {
    print("Fehler: gsPath ist leer.");
    return '';
  }

  if (!gsPath.startsWith('gs://')) {
    print("Fehler: Kein gs:// Pfad: $gsPath");
    return '';
  }

  try {
    final storage = FirebaseStorage.instance;

    // Extrahiere und dekodiere den Pfad
    final uri = Uri.parse(gsPath);
    final path = Uri.decodeComponent(uri.path.substring(1));

    // Verwende ref() mit dem dekodierten Pfad
    final Reference gsReference = storage.ref(path);
    final String downloadUrl = await gsReference.getDownloadURL();

    return downloadUrl;
  } on FirebaseException catch (e) {
    print('Firebase Storage Fehler ($gsPath): ${e.code} - ${e.message}');
    return '';
  } catch (e) {
    print('Allgemeiner Fehler beim Abrufen der URL für $gsPath: $e');
    return '';
  }
}

class _HomeState extends State<Home> {
  final getChardData _cardData = getChardData();
  late Future<List<Map<String, dynamic>>> cards = _cardData
      .getAllCardsFromBannlist();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: cards,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Fehler: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final cards = snapshot.data!;
              return ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];

                  return FutureBuilder<String>(
                    future: getImgPath(card["card_images"][0]["image_url"]),
                    builder: (context, imgSnapshot) {
                      return ListTile(
                        title: Text(card['name'] ?? 'Unbekannt'),
                        trailing:
                            imgSnapshot.connectionState ==
                                    ConnectionState.done &&
                                imgSnapshot.hasData &&
                                imgSnapshot.data!.isNotEmpty
                            ? Image.network(
                                imgSnapshot.data!,
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              )
                            : const SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      );
                    },
                  );
                },
              );
            } else {
              return const Center(child: Text("Keine Karten gefunden"));
            }
          },
    );
  }
}
