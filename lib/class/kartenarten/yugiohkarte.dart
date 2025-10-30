class YugiohKarte {
  final int idNumber;
  final String name;
  final String type;
  final String frameType;
  final String desc;
  final bool hasEffect;
  final List<String> formats;
  final List<String> treatedAs;
  final String imagePath;

  final String? betaName;
  final int? views;
  final int? viewsweek;
  final int? upvotes;
  final int? downvotes;
  final DateTime? tcgDate;
  final DateTime? ocgDate;
  final int? konamiid;
  final String? mdRarity;

  final int? genesysPoints;

  YugiohKarte({
    this.betaName,
    this.views,
    this.viewsweek,
    this.upvotes,
    this.downvotes,
    this.formats = const [],
    this.treatedAs = const [],
    this.tcgDate,
    this.ocgDate,
    this.konamiid,
    this.mdRarity,
    required this.hasEffect,
    this.genesysPoints,
    required this.idNumber,
    required this.name,
    required this.type,
    required this.frameType,
    required this.desc,
    required this.imagePath,
  });
}
