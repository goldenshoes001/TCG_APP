import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_app/class/DatabaseRepo/database_repository.dart';
import 'package:tcg_app/class/fallenkarte.dart';
import 'package:tcg_app/class/kommentar.dart';
import 'package:tcg_app/class/monstercard.dart';
import 'package:tcg_app/class/yugiohkarte.dart';
import 'package:tcg_app/class/zauberkarte.dart';
import 'package:tcg_app/theme/dark_theme.dart';

class MockDatabaseRepository implements DatabaseRepository {
  static MockDatabaseRepository? _instance;
  static int i = 0;
  MockDatabaseRepository._internal();

  factory MockDatabaseRepository() {
    _instance ??= MockDatabaseRepository._internal();
    return _instance!;
  }

  // Zentralisierte Listen für die Daten
  static final List<String> cardTypes = [
    "monster", // 0
    "spell", // 1
    "trap", // 2
  ];

  static final List<String> attributes = [
    "Dark", // 0
    "wind", // 1
    "fire", // 2
    "light", // 3
    "water", // 4
    "earth", // 5
  ];

  static final List<String> types = [
    "Cyberse", // 0
    "winged beast", // 1
    "dragon", // 2
    "zombie", // 3
    "rock", // 4
    "warrior", // 5
    "Reptile", // 6
  ];

  static final List<List<String>> archetypes = [
    ["maliss"], // 0
    ["@Ignister"], // 1
    ["mulcharmy"], // 2
    ["bystial"], // 3
    ["handtrap"], // 4
    ["staple"], // 5
    ["Salamangreat"], // 6
    ["@Ignister"], // 7
    ["code talker", "@Ignister"], // 8
    ["code talker", "staple"], // 9
  ];

  static final List<String> deckTypes = [
    "main-deck", // 0
    "monster", // 1
    "extraDeck", // 2
  ];

  static final List<String> subtypes = [
    "effect", // 0
    "effect-monster", // 1
    "link", // 2
    "normal-spell", // 3
    "quick-play", // 4
    "field", // 5
    "normal-trap", // 6
    "link Monster", // 7
  ];

  static final List<YugiohKarte> _cardList = [
    Monstercard(
      imagePath: "assets/images/maliss/chessycat.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss <P> Chessy Cat",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 1500,
      def: 300,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          "Any monster destroyed by battle with a Maliss Link Monster that points to this card is banished. You can only use each of the following effects of Maliss <P> Chessy Cat once per turn. During your Main Phase: You can banish 1 \"Maliss\" card from your hand, then you can draw 2 cards. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),
    Monstercard(
      imagePath: "assets/images/maliss/Dormaus.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss <P> Dormouse",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 900,
      def: 300,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          "Maliss Link Monsters that point to this card cannot be destroyed by card effects. You can only use each of the following effects of \"Maliss <P> Dormouse\" once per turn. During your Main Phase: You can activate this effect; banish 1 \"Maliss\" monster from your Deck, also for the rest of this turn, \"Maliss\" monsters you control gain 600 ATK. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),

    Monstercard(
      imagePath: "assets/images/maliss/White Rabbit.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss <P> White Rabbit",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 1500,
      def: 300,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          "You take no damage from battles involving \"Maliss\" Link Monsters that point to this card. You can only use each of the following effects of \"Maliss White Rabbit\" once per turn. If this card is Normal or Special Summoned: You can Set 1 \"Maliss\" Trap from your Deck with a different name than the cards in your GY. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),
    Monstercard(
      imagePath: "assets/images/maliss/Maerzhase.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss <P> March Hare",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 600,
      def: 300,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          "Your opponent cannot target \"Maliss\" Link Monsters that point to this card with card effects. You can only use each of the following effects of \"Maliss March Hare\" once per turn. During the Main Phase, if this card is in your hand (Quick Effect): You can banish 1 other \"Maliss\" card from your hand or GY, and if you do, Special Summon this card. If this card is banished: You can pay 300 LP, then target 1 of your banished \"Maliss\" monsters; add it to your hand.",
    ),
    Monstercard(
      imagePath: "assets/images/Cyberse/Wizzard.jpg",
      archetype: archetypes[1],
      idNumber: i++,
      name: "Wizard @Ignister",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 4,
      atk: 1800,
      def: 800,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          "If you control a Cyberse monster that was Special Summoned from the Extra Deck: You can target 1 DARK Cyberse monster in your GY; Special Summon both this card in your hand and that monster, in Defense Position, also you cannot Special Summon for the rest of this turn, except Cyberse monsters. You can banish this card from your field or GY, then target 1 monster your opponent controls; change its battle position. You can only use each effect of \"Wizard @Ignister\" once per turn.",
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/fuwalos.jpg",
      archetype: archetypes[2],
      idNumber: i++,
      name: "Mulcharmy Fuwalos",
      cardType: cardTypes[0],
      attribute: attributes[1],
      type: types[1],
      level: 4,
      atk: 100,
      def: 600,
      deckType: deckTypes[0],
      subtype: subtypes[0],
      cardText:
          '''If you control no cards (Quick Effect): You can discard this card; apply these effects this turn 

      ● Each time your opponent Special Summons a monster(s) from the Deck and/or Extra Deck, immediately draw 1 card.

      ● Once, during this End Phase, if the number of cards in your hand is more than the number of cards your opponent controls +6, you must randomly shuffle cards from your hand into the Deck so the number in your hand equals the number your opponent controls +6.

      You can only activate 1 other "Mulcharmy" monster effect, the turn you activate this effect.''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/magmahut.jpg",
      archetype: archetypes[3],
      idNumber: i++,
      name: "Bystial Magnamhut",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[2],
      level: 6,
      atk: 2500,
      def: 2000,
      deckType: deckTypes[1],
      subtype: subtypes[1],
      cardText: '''
          You can target 1 LIGHT or DARK monster in either GY; banish it, and if you do, Special Summon this card from your hand. This is a Quick Effect if your opponent controls a monster. If this card is Special Summoned: You can activate this effect; during the End Phase of this turn, add 1 Dragon monster from your Deck or GY to your hand, except "Bystial Magnamhut". You can only use each effect of "Bystial Magnamhut" once per turn.
          ''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/druiswurm.jpg",
      archetype: archetypes[3],
      idNumber: i++,
      name: "Bystial Druiswurm",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[2],
      level: 6,
      atk: 2500,
      def: 2000,
      deckType: deckTypes[0],
      subtype: subtypes[1],
      cardText: '''
      If you control no cards (Quick Effect): You can discard this card; apply these effects this turn. 
      
      ● Each time your opponent Normal or Special Summons a monster(s) from the hand, immediately draw 1 card.
      
      ● Once, during this End Phase, if the number of cards in your hand is more than the number of cards your opponent controls +6, you must randomly shuffle cards from your hand into the Deck so the number in your hand equals the number your opponent controls +6.

      You can only activate 1 other "Mulcharmy" monster effect, the turn you activate this effect.
      ''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/ash.jpg",
      archetype: archetypes[4],
      idNumber: i++,
      name: "Ash Blossom & Joyous Spring",
      cardType: cardTypes[0],
      attribute: attributes[2],
      type: types[3],
      level: 3,
      atk: 0,
      def: 1800,
      deckType: deckTypes[0],
      subtype: subtypes[1],
      cardText: '''
      When a card or effect is activated that includes any of these effects (Quick Effect): You can discard this card; negate that effect.
      ● Add a card from the Deck to the hand.
      ● Special Summon from the Deck.
      ● Send a card from the Deck to the GY.
      You can only use this effect of "Ash Blossom & Joyous Spring" once per turn.
''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/nibiru.jpg",
      archetype: archetypes[4],
      idNumber: i++,
      name: "Nibiru, the Primal Being",
      cardType: cardTypes[0],
      attribute: attributes[3],
      type: types[4],
      level: 11,
      atk: 3000,
      def: 600,
      deckType: deckTypes[0],
      subtype: subtypes[1],
      cardText:
          "During the Main Phase, if your opponent Normal or Special Summoned 5 or more monsters this turn (Quick Effect): You can Tribute as many face-up monsters on the field as possible, and if you do, Special Summon this card from your hand, then Special Summon 1 \"Primal Being Token\" (Rock/LIGHT/Level 11/ATK ?/DEF ?) to your opponent's field. (This Token's ATK/DEF become the combined original ATK/DEF of the Tributed monsters.) You can only use this effect of \"Nibiru, the Primal Being\" once per turn.",
    ),
    Zauberkarte(
      imagePath: "assets/images/maliss/Maliss in Underground.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss in Underground",
      cardType: cardTypes[1],
      spellcardType: subtypes[5],
      text:
          '''When this card is activated: You can banish 1 "Maliss" card from your hand, Deck, or GY. While 3 or more of your "Maliss" Traps with different names are banished, "Maliss" Link Monsters you control gain 3000 ATK. While you control a "Maliss" Link Monster, your opponent's monsters can only target "Maliss" Link Monsters for attacks. You can only activate 1 "Maliss in Underground" per turn.''',
    ),
    Zauberkarte(
      imagePath: "assets/images/maliss/maliss in mirror.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss in the Mirror",
      cardType: cardTypes[1],
      text: '''
      Target 1 face-up monster your opponent controls; banish 1 "Maliss" monster from your hand or face-up field, and if you do, negate that monster's effects until the end of this turn. If this card is banished: You can target 1 "Maliss" card in your GY; banish it, and if you do, add 1 "Maliss" card of the same type (Monster, Spell, or Trap) from your Deck to your hand. You can only use each effect of "Maliss in the Mirror" once per turn. 
      spellcardType: 'quick-play''',
      spellcardType: subtypes[4],
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/talents.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "Triple Tactics Talent",
      cardType: cardTypes[1],
      text: '''
      If your opponent has activated a monster effect during your Main Phase this turn: Activate 1 of these effects;
      ● Draw 2 cards.
      ● Take control of 1 monster your opponent controls until the End Phase.
      ● Look at your opponent's hand, and choose 1 card from it to shuffle into the Deck.

      You can only activate 1 "Triple Tactics Talent" per turn.
          ''',
      spellcardType: subtypes[3],
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/sagrophag.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "Gold Sarcophagus",
      cardType: cardTypes[1],
      text: '''
      During your Main Phase: You can banish 1 card from your hand, then add 1 "Maliss" card from your Deck to your hand. You can only use this effect of "Gold Sarcophagus" once per turn.
      ''',
      spellcardType: subtypes[3],
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/teraforming.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "Terraforming",
      cardType: cardTypes[1],
      text: '''Add 1 Field Spell from your Deck to your hand''',
      spellcardType: subtypes[3],
    ),
    Fallenkarte(
      imagePath: "assets/images/handtraps/imperm.jpg",
      archetype: archetypes[4],
      idNumber: i++,
      name: "Infinite Impermanence",
      cardType: cardTypes[2],
      text:
          "Target 1 face-up monster your opponent controls; negate its effects (until the end of this turn), then, if this card was Set before activation and is on the field at resolution, for the rest of this turn all other Spell/Trap effects in this column are negated. If you control no cards, you can activate this card from your hand.",
      fallenTyp: subtypes[6],
    ),
    Fallenkarte(
      imagePath: "assets/images/handtraps/impulse.jpg",
      archetype: archetypes[4],
      idNumber: i++,
      name: "Dominus Impulse",
      cardType: cardTypes[2],
      text: ''' 
         If your opponent controls a card, you can activate this card from your hand. When a card or effect is activated that includes an effect that Special Summons a monster(s): Negate that effect, then if you have a Trap in your GY, destroy that card. If you activated this card from your hand, you cannot activate the effects of LIGHT, EARTH, and WIND monsters for the rest of this Duel. You can only activate 1 "Dominus Impulse" per turn.''',
      fallenTyp: subtypes[6],
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/gwc.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss GWC-06t",
      cardType: cardTypes[2],
      fallenTyp: subtypes[6],
      text:
          'You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Special Summon 1 of your "Maliss" monsters that is banished or in your GY, then if you control a "Maliss" Link Monster, you can gain LP equal to the original ATK of that Special Summoned monster. You can only activate 1 "Maliss GWC-06" per turn.'
          '',
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/mtp.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss MTP-07",
      cardType: cardTypes[2],
      text:
          '''You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Add 1 "Maliss" monster from your Deck to your hand, then if you control a "Maliss" Link Monster, you can banish 1 card on the field. You can only activate 1 "Maliss MTP-07" per turn''',
      fallenTyp: subtypes[6],
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/tp.jpg",
      idNumber: i++,
      name: "Maliss TP-11",
      cardType: cardTypes[2],
      fallenTyp: subtypes[6],
      text: '''
          You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Special Summon 1 "Maliss" monster from your Deck, or if your opponent controls 3 or more cards, you can Special Summon 1 "Maliss" Link Monster from your Extra Deck instead. For the rest of this turn, that Summoned monster cannot attack and neither player can activate its effects. You can only activate 1 "Maliss TP-11" per turn.
      ''',
      archetype: archetypes[0],
    ),

    Monstercard(
      imagePath: "assets/images/maliss/Hearts Crypter.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss Hearts Crypter",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 2500,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''3 monsters, including a "Maliss" monster
(Quick Effect): You can target 1 of your banished "Maliss" cards; shuffle it into the Deck, and if you do, banish 1 card on the field (while this card points to a monster, this effect and its activation cannot be negated). If this card is banished: You can pay 900 LP; Special Summon it and double its ATK. You can only use each effect of "Maliss Hearts Crypter" once per turn.''',
    ),

    Monstercard(
      imagePath: "assets/images/maliss/Red Ransom.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss Red Ransom",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 3,
      atk: 2300,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2+ monsters, including a "Maliss" monster
While this card points to a monster, the original ATK and DEF of all Effect Monsters your opponent controls are switched. You can only use each of the following effects of "Maliss Red Ransom" once per turn. If this card is Special Summoned: You can add 1 "Maliss" Spell from your Deck to your hand. If this card is banished: You can pay 900 LP; Special Summon it, then you can banish 1 Cyberse monster from your Deck.''',
    ),
    Monstercard(
      imagePath: "assets/images/maliss/White Binder.jpg",
      archetype: archetypes[0],
      idNumber: i++,
      name: "Maliss White Binder",
      cardType: cardTypes[0],
      attribute: attributes[3],
      type: types[0],
      level: 3,
      atk: 2300,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2+ monsters, including a "Maliss" monster
If this card is Special Summoned: You can target up to 3 cards in any GY(s); banish them. During your Main Phase: You can Set 1 "Maliss" Trap from your Deck or GY. If this card is banished: You can pay 900 LP; Special Summon it, then you can draw 1 card. You can only use each effect of "Maliss White Binder" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/wickkid.jpg",
      archetype: archetypes[1],
      idNumber: i++,
      name: "Cyberse Wicckid",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 2,
      atk: 800,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2 Cyberse monsters
This Link Summoned card cannot be destroyed by battle or card effects. Cyberse monsters this card points to cannot be destroyed by card effects. If a monster(s) is Special Summoned to a zone(s) this card points to while you control this monster (except during the Damage Step): You can banish 1 Cyberse monster from your GY; add 1 Cyberse Tuner from your Deck to your hand. You can only use this effect of "Cyberse Wicckid" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/link disciple.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "Link Disciple",
      cardType: cardTypes[0],
      attribute: attributes[3],
      type: types[0],
      level: 1,
      atk: 500,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''1 Level 4 or lower Cyberse monster
You can Tribute 1 monster this card points to; draw 1 card, then place 1 card from your hand on the bottom of the Deck. You can only use this effect of "Link Disciple" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/splash mage.jpg",
      archetype: archetypes[1],
      idNumber: i++,
      name: "Splash Mage",
      cardType: cardTypes[0],
      attribute: attributes[4],
      type: types[0],
      level: 2,
      atk: 1100,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2 Cyberse monsters
You can target 1 Cyberse monster in your GY; Special Summon it in Defense Position, but negate its effects, also you cannot Special Summon monsters for the rest of this turn, except Cyberse monsters. You can only use this effect of "Splash Mage" once per turn''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/firewall dragon.jpg",
      archetype: archetypes[1],
      idNumber: i++,
      name: "Firewall Dragon",
      cardType: cardTypes[0],
      attribute: attributes[3],
      type: types[0],
      level: 4,
      atk: 2500,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2+ monsters
Once while face-up on the field (Quick Effect): You can target monsters on the field and/or GY up to the number of monsters co-linked to this card; return them to the hand. If a monster this card points to is destroyed by battle or sent to the GY: You can Special Summon 1 Cyberse monster from your hand. You can only use each effect of "Firewall Dragon" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/link spider.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "link spider",
      cardType: cardTypes[0],
      attribute: attributes[5],
      type: types[0],
      level: 1,
      atk: 1000,
      deckType: deckTypes[1],
      subtype: subtypes[7],
      cardText:
          "Once per turn: You can Special Summon 1 Level 4 or lower Normal Monster from your hand to your zone this card points to.",
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/almiraj.jpg",
      archetype: archetypes[6],
      idNumber: i++,
      name: "Salamangreat Almiraj",
      cardType: cardTypes[0],
      attribute: attributes[2],
      type: types[0],
      level: 1,
      atk: 0,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''1 Normal Summoned monster with 1000 or less ATK
(Quick Effect): You can Tribute this card, then target 1 monster you control; it cannot be destroyed by your opponent's card effects this turn. When a Normal Summoned monster you control is destroyed by battle, while this card is in your GY: You can Special Summon this card. You can only use this effect of "Salamangreat Almiraj" once per turn''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/linguriboh.jpg",
      archetype: archetypes[7],
      idNumber: i++,
      name: "Linguriboh",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 1,
      atk: 300,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''1 Level 4 or lower Cyberse monster
When your opponent activates a Trap Card (Quick Effect): You can Tribute this card; negate that card's effect, and if you do, banish it. If this card is in your GY (Quick Effect): You can Tribute 1 "@Ignister" monster that was Summoned from the Extra Deck; Special Summon this card. You can only use each effect of "Linguriboh" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/allied code talker.jpg",
      archetype: archetypes[8],
      idNumber: i++,
      name: "Allied Code Talker @Ignister",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 5,
      atk: 2300,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''3+ Effect Monsters
If this card is Link Summoned: You can Special Summon as many Cyberse monsters with 2300 ATK from your GY as possible to your zones this card points to, and if you do, this card gains 500 ATK for each, also you cannot Special Summon for the rest of this turn. When your opponent activates a card or effect (Quick Effect): You can Tribute 1 of your Link Monsters this card points to; negate the activation, and if you do, banish that card. You can only use this effect of "Allied Code Talker @Ignister" once per turn.''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/code talker.jpg",
      archetype: archetypes[9],
      idNumber: i++,
      name: "Accesscode Talker",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 4,
      atk: 2300,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2+ Effect Monsters
Your opponent cannot activate cards or effects in response to this card's effect activations. If this card is Link Summoned: You can target 1 Link Monster that was used as material for its Link Summon; this card gains ATK equal to that monster's Link Rating x 1000. You can banish 1 Link Monster from your field or GY; destroy 1 card your opponent controls, also for the rest of this turn, you cannot banish monsters with that same Attribute to activate this effect of "Accesscode Talker".''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/ip.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "I:P Masquerena",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[0],
      level: 2,
      atk: 800,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2 non-Link Monsters
During your opponent's Main Phase, you can (Quick Effect): Immediately after this effect resolves, Link Summon 1 Link Monster using materials you control, including this card. You can only use this effect of "I:P Masquerena" once per turn. A Link Monster that used this card as material cannot be destroyed by your opponent's card effects.''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/s-p.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "S:P Little Knight",
      cardType: cardTypes[0],
      attribute: attributes[0],
      type: types[5],
      level: 2,
      atk: 1600,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2 Effect Monsters
If this card is Link Summoned using a Fusion, Synchro, Xyz, or Link Monster as material: You can target 1 card on the field or in either GY; banish it, also your monsters cannot attack directly this turn. When your opponent activates a card or effect (Quick Effect): You can target 2 face-up monsters on the field, including a monster you control; banish both until the End Phase. You can only use each effect of "S:P Little Knight" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/haggard Lizardose.jpg",
      archetype: archetypes[5],
      idNumber: i++,
      name: "Haggard Lizardose",
      cardType: cardTypes[0],
      attribute: attributes[4],
      type: types[6],
      level: 2,
      atk: 800,
      deckType: deckTypes[2],
      subtype: subtypes[2],
      cardText: '''2 monsters with different names
You can banish 1 monster from your face-up field or GY with 2000 or less ATK, then target 1 face-up monster on the field; make its ATK become equal to the original ATK of the monster banished to activate this effect (until the end of this turn), then if you banished a monster that was originally Reptile, draw 1 card. You can only use this effect of "Haggard Lizardose" once per turn.''',
    ),
  ];

  @override
  Future<List<YugiohKarte>> getallCards() async {
    await Future.delayed(Duration(seconds: 1));
    return _cardList;
  }

  @override
  Future<List<Kommentar>> bekommeAlleKommentare() {
    // TODO: implement bekommeAlleKommentare
    throw UnimplementedError();
  }

  @override
  Future<void> deleteKommentar() {
    // TODO: implement deleteKommentar
    throw UnimplementedError();
  }

  @override
  Future<void> deleteNutzer() {
    // TODO: implement deleteNutzer
    throw UnimplementedError();
  }

  @override
  Future<Kommentar> erstelleKommentar() {
    // TODO: implement erstelleKommentar
    throw UnimplementedError();
  }

  @override
  Future<User> erstelleNutzer() {
    // TODO: implement erstelleNutzer
    throw UnimplementedError();
  }

  @override
  Future<Kommentar> findeKommentar() {
    // TODO: implement findeKommentar
    throw UnimplementedError();
  }

  @override
  Future<User> leseNutzerDaten() {
    // TODO: implement leseNutzerDaten
    throw UnimplementedError();
  }

  @override
  Future<void> updateKommentar() {
    // TODO: implement updateKommentar
    throw UnimplementedError();
  }

  @override
  Future<User> updateNutzer() {
    // TODO: implement updateNutzer
    throw UnimplementedError();
  }
}
