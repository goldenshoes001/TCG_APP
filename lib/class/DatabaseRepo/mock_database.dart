import 'dart:ui';

import 'package:tcg_app/class/DatabaseRepo/database_repository.dart';
import 'package:tcg_app/class/fallenkarte.dart';
import 'package:tcg_app/class/kommentar.dart';
import 'package:tcg_app/class/monstercard.dart';
import 'package:tcg_app/class/user.dart';
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
  static final List<YugiohKarte> _cardList = [
    Monstercard(
      imagePath: "assets/images/maliss/chessycat.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss <P> Chessy Cat",
      cardType: "monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 3,
      atk: 1500,
      def: 300,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          "Any monster destroyed by battle with a Maliss Link Monster that points to this card is banished. You can only use each of the following effects of Maliss <P> Chessy Cat once per turn. During your Main Phase: You can banish 1 \"Maliss\" card from your hand, then you can draw 2 cards. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),
    Monstercard(
      imagePath: "assets/images/maliss/Dormaus.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss <P> Dormouse",
      cardType: "monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 3,
      atk: 900,
      def: 300,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          "Maliss Link Monsters that point to this card cannot be destroyed by card effects. You can only use each of the following effects of \"Maliss <P> Dormouse\" once per turn. During your Main Phase: You can activate this effect; banish 1 \"Maliss\" monster from your Deck, also for the rest of this turn, \"Maliss\" monsters you control gain 600 ATK. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),

    Monstercard(
      imagePath: "assets/images/maliss/White Rabbit.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss <P> White Rabbit",
      cardType: "monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 3,
      atk: 1500,
      def: 300,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          "You take no damage from battles involving \"Maliss\" Link Monsters that point to this card. You can only use each of the following effects of \"Maliss White Rabbit\" once per turn. If this card is Normal or Special Summoned: You can Set 1 \"Maliss\" Trap from your Deck with a different name than the cards in your GY. If this card is banished: You can pay 300 LP; Special Summon it, also you cannot Special Summon from the Extra Deck for the rest of this turn, except Link Monsters.",
    ),
    Monstercard(
      imagePath: "assets/images/maliss/Maerzhase.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss <P> March Hare",
      cardType: "monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 3,
      atk: 600,
      def: 300,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          "Your opponent cannot target \"Maliss\" Link Monsters that point to this card with card effects. You can only use each of the following effects of \"Maliss March Hare\" once per turn. During the Main Phase, if this card is in your hand (Quick Effect): You can banish 1 other \"Maliss\" card from your hand or GY, and if you do, Special Summon this card. If this card is banished: You can pay 300 LP, then target 1 of your banished \"Maliss\" monsters; add it to your hand.",
    ),
    Monstercard(
      imagePath: "assets/images/Cyberse/Wizzard.jpg",
      archetype: "cyberse",
      idNumber: i++,
      name: "Wizard @Ignister",
      cardType: "monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 4,
      atk: 1800,
      def: 800,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          "If you control a Cyberse monster that was Special Summoned from the Extra Deck: You can target 1 DARK Cyberse monster in your GY; Special Summon both this card in your hand and that monster, in Defense Position, also you cannot Special Summon for the rest of this turn, except Cyberse monsters. You can banish this card from your field or GY, then target 1 monster your opponent controls; change its battle position. You can only use each effect of \"Wizard @Ignister\" once per turn.",
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/fuwalos.jpg",
      archetype: "mulcharmy",
      idNumber: i++,
      name: "Mulcharmy Fuwalos",
      cardType: "monster",
      attribute: "wind",
      type: "winged beast",
      level: 4,
      atk: 100,
      def: 600,
      deckType: "main-deck",
      subtype: "effect",
      cardText:
          '''If you control no cards (Quick Effect): You can discard this card; apply these effects this turn 

      ● Each time your opponent Special Summons a monster(s) from the Deck and/or Extra Deck, immediately draw 1 card.

      ● Once, during this End Phase, if the number of cards in your hand is more than the number of cards your opponent controls +6, you must randomly shuffle cards from your hand into the Deck so the number in your hand equals the number your opponent controls +6.

      You can only activate 1 other \"Mulcharmy\" monster effect, the turn you activate this effect.''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/magmahut.jpg",
      archetype: "bystial",
      idNumber: i++,
      name: "Bystial Magnamhut",
      cardType: "monster",
      attribute: "Dark",
      type: "dragon",
      level: 6,
      atk: 2500,
      def: 2000,
      deckType: "monster",
      subtype: "effect-monster",
      cardText: '''
          You can target 1 LIGHT or DARK monster in either GY; banish it, and if you do, Special Summon this card from your hand. This is a Quick Effect if your opponent controls a monster. If this card is Special Summoned: You can activate this effect; during the End Phase of this turn, add 1 Dragon monster from your Deck or GY to your hand, except "Bystial Magnamhut". You can only use each effect of "Bystial Magnamhut" once per turn.
          ''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/druiswurm.jpg",
      archetype: "bystial",
      idNumber: i++,
      name: "Bystial Druiswurm",
      cardType: "monster",
      attribute: "dark",
      type: "dragon",
      level: 6,
      atk: 2500,
      def: 2000,
      deckType: "main-deck",
      subtype: "effect-monster",
      cardText: '''
      If you control no cards (Quick Effect): You can discard this card; apply these effects this turn. 
      
      ● Each time your opponent Normal or Special Summons a monster(s) from the hand, immediately draw 1 card.
      
      ● Once, during this End Phase, if the number of cards in your hand is more than the number of cards your opponent controls +6, you must randomly shuffle cards from your hand into the Deck so the number in your hand equals the number your opponent controls +6.

      You can only activate 1 other "Mulcharmy" monster effect, the turn you activate this effect.
      ''',
    ),
    Monstercard(
      imagePath: "assets/images/handtraps/ash.jpg",
      archetype: "handtrap",
      idNumber: i++,
      name: "Ash Blossom & Joyous Spring",
      cardType: "monster",
      attribute: "fire",
      type: "zombie",
      level: 3,
      atk: 0,
      def: 1800,
      deckType: "main-deck",
      subtype: "effect-monster",
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
      archetype: "handtrap",
      idNumber: i++,
      name: "Nibiru, the Primal Being",
      cardType: "monster",
      attribute: "light",
      type: "rock",
      level: 11,
      atk: 3000,
      def: 600,
      deckType: "main-deck",
      subtype: "effect-monster",
      cardText:
          "During the Main Phase, if your opponent Normal or Special Summoned 5 or more monsters this turn (Quick Effect): You can Tribute as many face-up monsters on the field as possible, and if you do, Special Summon this card from your hand, then Special Summon 1 \"Primal Being Token\" (Rock/LIGHT/Level 11/ATK ?/DEF ?) to your opponent's field. (This Token's ATK/DEF become the combined original ATK/DEF of the Tributed monsters.) You can only use this effect of \"Nibiru, the Primal Being\" once per turn.",
    ),
    Zauberkarte(
      imagePath: "assets/images/maliss/Maliss in Underground.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss in Underground",
      cardType: "spell",
      spellcardType: 'field',
      text:
          '''When this card is activated: You can banish 1 "Maliss" card from your hand, Deck, or GY. While 3 or more of your "Maliss" Traps with different names are banished, "Maliss" Link Monsters you control gain 3000 ATK. While you control a "Maliss" Link Monster, your opponent's monsters can only target "Maliss" Link Monsters for attacks. You can only activate 1 "Maliss in Underground" per turn.''',
    ),
    Zauberkarte(
      imagePath: "assets/images/maliss/maliss in mirror.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss in the Mirror",
      cardType: "spell",
      text: '''
      Target 1 face-up monster your opponent controls; banish 1 "Maliss" monster from your hand or face-up field, and if you do, negate that monster's effects until the end of this turn. If this card is banished: You can target 1 "Maliss" card in your GY; banish it, and if you do, add 1 "Maliss" card of the same type (Monster, Spell, or Trap) from your Deck to your hand. You can only use each effect of "Maliss in the Mirror" once per turn. 
      spellcardType: 'quick-play''',
      spellcardType: 'quick-play',
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/talents.jpg",
      archetype: "",
      idNumber: i++,
      name: "Triple Tactics Talent",
      cardType: "spell",
      text: '''
      If your opponent has activated a monster effect during your Main Phase this turn: Activate 1 of these effects;
      ● Draw 2 cards.
      ● Take control of 1 monster your opponent controls until the End Phase.
      ● Look at your opponent's hand, and choose 1 card from it to shuffle into the Deck.

      You can only activate 1 "Triple Tactics Talent" per turn.
          ''',
      spellcardType: 'normal-spell',
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/sagrophag.jpg",
      archetype: "staple",
      idNumber: i++,
      name: "Gold Sarcophagus",
      cardType: "spell",
      text: '''
      During your Main Phase: You can banish 1 card from your hand, then add 1 "Maliss" card from your Deck to your hand. You can only use this effect of "Gold Sarcophagus" once per turn.
      ''',
      spellcardType: 'normal-spell',
    ),
    Zauberkarte(
      imagePath: "assets/images/staples/teraforming.jpg",
      archetype: "staple",
      idNumber: i++,
      name: "Terraforming",
      cardType: "spell",
      text: '''Add 1 Field Spell from your Deck to your hand''',
      spellcardType: 'normal-spell',
    ),
    Fallenkarte(
      imagePath: "assets/images/handtraps/imperm.jpg",
      archetype: "handfallen",
      idNumber: i++,
      name: "Infinite Impermanence",
      cardType: "trap",
      text:
          "Target 1 face-up monster your opponent controls; negate its effects (until the end of this turn), then, if this card was Set before activation and is on the field at resolution, for the rest of this turn all other Spell/Trap effects in this column are negated. If you control no cards, you can activate this card from your hand.",
      fallenTyp: 'normal-trap',
    ),
    Fallenkarte(
      imagePath: "assets/images/handtraps/impulse.jpg",
      archetype: "handfallen",
      idNumber: i++,
      name: "Dominus Impulse",
      cardType: "trap",
      text: ''' 
         If your opponent controls a card, you can activate this card from your hand. When a card or effect is activated that includes an effect that Special Summons a monster(s): Negate that effect, then if you have a Trap in your GY, destroy that card. If you activated this card from your hand, you cannot activate the effects of LIGHT, EARTH, and WIND monsters for the rest of this Duel. You can only activate 1 "Dominus Impulse" per turn.''',
      fallenTyp: 'normal-trap',
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/gwc.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss GWC-06t",
      cardType: "trap",
      fallenTyp: 'normal-trap',
      text:
          'You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Special Summon 1 of your "Maliss" monsters that is banished or in your GY, then if you control a "Maliss" Link Monster, you can gain LP equal to the original ATK of that Special Summoned monster. You can only activate 1 "Maliss GWC-06" per turn.'
          '',
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/mtp.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss MTP-07",
      cardType: "trap",
      text:
          '''You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Add 1 "Maliss" monster from your Deck to your hand, then if you control a "Maliss" Link Monster, you can banish 1 card on the field. You can only activate 1 "Maliss MTP-07" per turn''',
      fallenTyp: "normal-trap",
    ),
    Fallenkarte(
      imagePath: "assets/images/maliss/tp.jpg",
      idNumber: i++,
      name: "Maliss TP-11",
      cardType: "trap",
      fallenTyp: "normal-trap",
      text: '''
          You can activate this card the turn it was Set, by banishing 1 face-up "Maliss" monster you control. Special Summon 1 "Maliss" monster from your Deck, or if your opponent controls 3 or more cards, you can Special Summon 1 "Maliss" Link Monster from your Extra Deck instead. For the rest of this turn, that Summoned monster cannot attack and neither player can activate its effects. You can only activate 1 "Maliss TP-11" per turn.
      ''',
      archetype: "maliss",
    ),

    Monstercard(
      imagePath: "assets/images/maliss/Hearts Crypter.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss Hearts Crypter",
      cardType: "Monster",
      attribute: "dark",
      type: "cyberse",
      level: 3,
      atk: 2500,
      deckType: "extraDeck",
      subtype: "link",
      cardText: '''3 monsters, including a "Maliss" monster
(Quick Effect): You can target 1 of your banished "Maliss" cards; shuffle it into the Deck, and if you do, banish 1 card on the field (while this card points to a monster, this effect and its activation cannot be negated). If this card is banished: You can pay 900 LP; Special Summon it and double its ATK. You can only use each effect of "Maliss Hearts Crypter" once per turn.''',
    ),

    Monstercard(
      imagePath: "assets/images/maliss/Red Ransom.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss Red Ransom",
      cardType: "Monster",
      attribute: "Dark",
      type: "cyberse",
      level: 3,
      atk: 2300,
      deckType: "extraDeck",
      subtype: "link",
      cardText: '''2+ monsters, including a "Maliss" monster
While this card points to a monster, the original ATK and DEF of all Effect Monsters your opponent controls are switched. You can only use each of the following effects of "Maliss Red Ransom" once per turn. If this card is Special Summoned: You can add 1 "Maliss" Spell from your Deck to your hand. If this card is banished: You can pay 900 LP; Special Summon it, then you can banish 1 Cyberse monster from your Deck.''',
    ),
    Monstercard(
      imagePath: "assets/images/maliss/White Binder.jpg",
      archetype: "maliss",
      idNumber: i++,
      name: "Maliss White Binder",
      cardType: "Monster",
      attribute: "Light",
      type: "cyberse",
      level: 3,
      atk: 2300,
      deckType: "extraDeck",
      subtype: "link",
      cardText: '''2+ monsters, including a "Maliss" monster
If this card is Special Summoned: You can target up to 3 cards in any GY(s); banish them. During your Main Phase: You can Set 1 "Maliss" Trap from your Deck or GY. If this card is banished: You can pay 900 LP; Special Summon it, then you can draw 1 card. You can only use each effect of "Maliss White Binder" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/wickkid.jpg",
      archetype: "cyberse",
      idNumber: i++,
      name: "Cyberse Wicckid",
      cardType: "Monster",
      attribute: "Dark",
      type: "Cyberse",
      level: 2,
      atk: 800,
      deckType: "extraDeck",
      subtype: "link",
      cardText: '''2 Cyberse monsters
This Link Summoned card cannot be destroyed by battle or card effects. Cyberse monsters this card points to cannot be destroyed by card effects. If a monster(s) is Special Summoned to a zone(s) this card points to while you control this monster (except during the Damage Step): You can banish 1 Cyberse monster from your GY; add 1 Cyberse Tuner from your Deck to your hand. You can only use this effect of "Cyberse Wicckid" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/link disciple.jpg",
      archetype: "",
      idNumber: i++,
      name: "Link Disciple",
      cardType: "Monster",
      attribute: "light",
      type: "cyberse",
      level: 1,
      atk: 500,
      deckType: "Extradeck",
      subtype: "link",
      cardText: '''1 Level 4 or lower Cyberse monster
You can Tribute 1 monster this card points to; draw 1 card, then place 1 card from your hand on the bottom of the Deck. You can only use this effect of "Link Disciple" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/splash mage.jpg",
      archetype: "",
      idNumber: i++,
      name: "Splash Mage",
      cardType: "Monster",
      attribute: "water ",
      type: "cyberse",
      level: 2,
      atk: 1100,
      deckType: "Extradeck",
      subtype: "link",
      cardText: '''2 Cyberse monsters
You can target 1 Cyberse monster in your GY; Special Summon it in Defense Position, but negate its effects, also you cannot Special Summon monsters for the rest of this turn, except Cyberse monsters. You can only use this effect of "Splash Mage" once per turn''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/firewall dragon.jpg",
      archetype: "",
      idNumber: i++,
      name: "Firewall Dragon",
      cardType: "Monster",
      attribute: "light",
      type: "cyberse",
      level: 4,
      atk: 2500,
      deckType: "Extradeck",
      subtype: "link",
      cardText: '''2+ monsters
Once while face-up on the field (Quick Effect): You can target monsters on the field and/or GY up to the number of monsters co-linked to this card; return them to the hand. If a monster this card points to is destroyed by battle or sent to the GY: You can Special Summon 1 Cyberse monster from your hand. You can only use each effect of "Firewall Dragon" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/link spider.jpg",
      archetype: "",
      idNumber: i++,
      name: "link spider",
      cardType: "Monster",
      attribute: "earth",
      type: "cyberse",
      level: 1,
      atk: 1000,
      deckType: "extradeck monster",
      subtype: "link Monster",
      cardText:
          "Once per turn: You can Special Summon 1 Level 4 or lower Normal Monster from your hand to your zone this card points to.",
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/almiraj.jpg",
      archetype: "Salamangreat",
      idNumber: i++,
      name: "Salamangreat Almiraj",
      cardType: "Monster",
      attribute: "fire",
      type: "cyberse",
      level: 1,
      atk: 0,
      deckType: "extradeck",
      subtype: "link",
      cardText: '''1 Normal Summoned monster with 1000 or less ATK
(Quick Effect): You can Tribute this card, then target 1 monster you control; it cannot be destroyed by your opponent's card effects this turn. When a Normal Summoned monster you control is destroyed by battle, while this card is in your GY: You can Special Summon this card. You can only use this effect of "Salamangreat Almiraj" once per turn''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/linguriboh.jpg",
      archetype: "",
      idNumber: i++,
      name: "Linguriboh",
      cardType: "monster",
      attribute: "dark",
      type: "cyberse",
      level: 1,
      atk: 300,
      deckType: "extradeck",
      subtype: "link",
      cardText: '''1 Level 4 or lower Cyberse monster
When your opponent activates a Trap Card (Quick Effect): You can Tribute this card; negate that card's effect, and if you do, banish it. If this card is in your GY (Quick Effect): You can Tribute 1 "@Ignister" monster that was Summoned from the Extra Deck; Special Summon this card. You can only use each effect of "Linguriboh" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/allied code talker.jpg",
      archetype: "@Ignister",
      idNumber: i++,
      name: "Allied Code Talker @Ignister",
      cardType: "Monster",
      attribute: "dark",
      type: "cyberse",
      level: 5,
      atk: 2300,
      deckType: "Extradeck",
      subtype: "link",
      cardText: '''3+ Effect Monsters
If this card is Link Summoned: You can Special Summon as many Cyberse monsters with 2300 ATK from your GY as possible to your zones this card points to, and if you do, this card gains 500 ATK for each, also you cannot Special Summon for the rest of this turn. When your opponent activates a card or effect (Quick Effect): You can Tribute 1 of your Link Monsters this card points to; negate the activation, and if you do, banish that card. You can only use this effect of "Allied Code Talker @Ignister" once per turn.''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/code talker.jpg",
      archetype: "code talker",
      idNumber: i++,
      name: "Accesscode Talker",
      cardType: "monster",
      attribute: "dark",
      type: "cyberse",
      level: 4,
      atk: 2300,
      deckType: "extradeck",
      subtype: "link",
      cardText: '''2+ Effect Monsters
Your opponent cannot activate cards or effects in response to this card's effect activations. If this card is Link Summoned: You can target 1 Link Monster that was used as material for its Link Summon; this card gains ATK equal to that monster's Link Rating x 1000. You can banish 1 Link Monster from your field or GY; destroy 1 card your opponent controls, also for the rest of this turn, you cannot banish monsters with that same Attribute to activate this effect of "Accesscode Talker".''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/ip.jpg",
      archetype: "",
      idNumber: i++,
      name: "I:P Masquerena",
      cardType: "monster",
      attribute: "dark",
      type: "cyberse",
      level: 2,
      atk: 800,
      deckType: "extradeck",
      subtype: "link",
      cardText: '''2 non-Link Monsters
During your opponent's Main Phase, you can (Quick Effect): Immediately after this effect resolves, Link Summon 1 Link Monster using materials you control, including this card. You can only use this effect of "I:P Masquerena" once per turn. A Link Monster that used this card as material cannot be destroyed by your opponent's card effects.''',
    ),

    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/s-p.jpg",
      archetype: "",
      idNumber: i++,
      name: "S:P Little Knight",
      cardType: "Monster",
      attribute: "dark",
      type: "warrior",
      level: 2,
      atk: 1600,
      deckType: "extradeck",
      subtype: "link",
      cardText: '''2 Effect Monsters
If this card is Link Summoned using a Fusion, Synchro, Xyz, or Link Monster as material: You can target 1 card on the field or in either GY; banish it, also your monsters cannot attack directly this turn. When your opponent activates a card or effect (Quick Effect): You can target 2 face-up monsters on the field, including a monster you control; banish both until the End Phase. You can only use each effect of "S:P Little Knight" once per turn.''',
    ),
    Monstercard(
      imagePath: "assets/images/ExtraDeck/Link/haggard Lizardose.jpg",
      archetype: "",
      idNumber: i++,
      name: "Haggard Lizardose",
      cardType: "monster",
      attribute: "water",
      type: "Reptile",
      level: 2,
      atk: 800,
      deckType: "extra Deck",
      subtype: "link",
      cardText: '''2 monsters with different names
You can banish 1 monster from your face-up field or GY with 2000 or less ATK, then target 1 face-up monster on the field; make its ATK become equal to the original ATK of the monster banished to activate this effect (until the end of this turn), then if you banished a monster that was originally Reptile, draw 1 card. You can only use this effect of "Haggard Lizardose" once per turn.''',
    ),
  ];
  void addYugiohKarte(YugiohKarte karte) {
    _cardList.add(karte);
  }

  List<YugiohKarte> getAllYugiohKarten() {
    return _cardList;
  }

  @override
  void deleteYugiohKarte(int id) {
    _cardList.removeWhere((karte) => karte.idNumber == id);
  }

  @override
  int showYugiohKarteID(YugiohKarte karte) {
    return karte.idNumber;
  }

  @override
  YugiohKarte findYugiohKarte(int id) {
    return _cardList[_cardList.indexWhere((karte) => karte.idNumber == id)];
  }

  @override
  Kommentar erstelleKommentar() {
    // TODO: implement erstelleKommentar
    throw UnimplementedError();
  }

  @override
  User erstelleNutzer() {
    // TODO: implement erstelleNutzer
    throw UnimplementedError();
  }

  @override
  Kommentar findeKommentar() {
    // TODO: implement findeKommentar
    throw UnimplementedError();
  }

  @override
  User leseNutzerDaten() {
    // TODO: implement leseNutzerDaten
    throw UnimplementedError();
  }

  @override
  void updateKommentar() {
    // TODO: implement updateKommentar
  }

  @override
  User updateNutzer() {
    // TODO: implement updateNutzer
    throw UnimplementedError();
  }

  @override
  List<Kommentar> bekommeAlleKommentare() {
    // TODO: implement bekommeAlleKommentare
    throw UnimplementedError();
  }

  @override
  void deleteKommentar() {
    // TODO: implement deleteKommentar
  }

  @override
  void deleteNutzer() {
    // TODO: implement deleteNutzer
  }
}
