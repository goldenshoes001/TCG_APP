import 'package:flutter/material.dart';
import 'package:tcg_app/class/DatabaseRepo/mock_database.dart';

import 'package:tcg_app/class/yugiohkarte.dart';

class Meta extends StatelessWidget {
  const Meta({super.key});

  @override
  Widget build(BuildContext context) {
    // Die Listen der Karten
    MockDatabaseRepository db = MockDatabaseRepository();
    Future<List<YugiohKarte>> listCards = db.getallCards();

    return FutureBuilder<List<YugiohKarte>>(
      future: listCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // You must return a widget here to show a loading state
          return CircularProgressIndicator();
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // You must return a widget here to display the data
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              YugiohKarte card = snapshot.data![index];
              return Card(
                child: ListTile(
                  title: Text(card.name),
                  leading: Image.asset(card.imagePath),
                ),
              );
            },
          );
        } else {
          return Text(
            'Es ist ein Fehler aufgetreten oder es gibt keine Daten.',
          );
        }
      },
    );
  }
}
