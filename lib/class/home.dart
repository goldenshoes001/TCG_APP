import 'package:flutter/material.dart';
import 'package:tcg_app/class/DatabaseRepo/mock_database.dart';
import 'package:tcg_app/class/yugiohkarte.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    MockDatabaseRepository db = MockDatabaseRepository();
    Future<List<YugiohKarte>> listCards = db.getallCards();

    return FutureBuilder<List<YugiohKarte>>(
      future: listCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return SingleChildScrollView(
            child: Column(
              children: [

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 20.0,
                          bottom: 40.0,
                        ),
                        child: ShowList(
                          snapshot: snapshot,
                          crossAxisCount: 1,
                          title: "Kategorie A",
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          bottom: 40.0,
                        ),
                        child: ShowList(
                          snapshot: snapshot,
                          crossAxisCount: 1,
                          title: "Kategorie B",
                        ),
                      ),
                    ),
                  ],
                ),


                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: SizedBox(
                    height:250,
                    child: ShowListHorizontal(
                      snapshot: snapshot,
                      crossAxisCount: 2, 
                      title: "Kategorie C",
                    ),
                  ),
                ),

               
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                 
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 10.0,
                          bottom: 40.0,
                        ),
                        child: ShowList(
                          snapshot: snapshot,
                          crossAxisCount: 1,
                          title: "Kategorie D",
                        ),
                      ),
                    ),
               
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ShowList(
                          snapshot: snapshot,
                          crossAxisCount: 1,
                          title: "Kategorie E",
                        ),
                      ),
                    ),
                 
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          bottom: 40.0,
                        ),
                        child: ShowList(
                          snapshot: snapshot,
                          crossAxisCount: 1,
                          title: "Kategorie F",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        } else {
          return const Center(
            child: Text(
              'Es ist ein Fehler aufgetreten oder es gibt keine Daten.',
            ),
          );
        }
      },
    );
  }
}

class ShowList extends StatelessWidget {
  final AsyncSnapshot<List<YugiohKarte>> snapshot;
  final int crossAxisCount;
  final String? title;

  const ShowList({
    super.key,
    required this.snapshot,
    this.crossAxisCount = 2,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
     
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

 
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 3.0,
            crossAxisSpacing: 2,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            YugiohKarte card = snapshot.data![index];
            return Card(
              margin: EdgeInsets.zero,
              color: Colors.transparent,
              elevation: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
               
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(card.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        card.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class ShowListHorizontal extends StatelessWidget {
  final AsyncSnapshot<List<YugiohKarte>> snapshot;
  final int crossAxisCount;
  final String? title;

  const ShowListHorizontal({
    super.key,
    required this.snapshot,
    this.crossAxisCount = 2,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
     
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

   
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio:
                  1.5, 
              crossAxisSpacing: 4,
              mainAxisSpacing: 8,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              YugiohKarte card = snapshot.data![index];
              return Card(
                margin: EdgeInsets.zero,
                color: Colors.transparent,
                elevation: 0,
                child: Column(
            
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                 
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(card.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                   
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          card.name,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
