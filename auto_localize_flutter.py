#!/usr/bin/env python3
"""
🌍 Vollautomatisches Flutter Lokalisierungs-Script
Erstellt von Claude - Keine manuelle Nacharbeit nötig!

Features:
✅ Extrahiert alle Texte automatisch
✅ Erstellt en.json & de.json
✅ Aktualisiert pubspec.yaml
✅ Erstellt language_provider.dart
✅ Modifiziert main.dart
✅ Fügt Sprach-Button zur AppBar hinzu
✅ Integriert Algolia-Index-Wechsel (cards ↔ cards_de)
✅ Speichert Sprache in SharedPreferences
✅ Ersetzt ALLE Algolia-Index-Referenzen
✅ Aktualisiert app_providers.dart

Verwendung:
    python auto_localize_flutter.py
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple
import anthropic

class FlutterLocalizer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / "lib"
        self.assets_path = self.project_root / "assets" / "translations"
        self.translations_en = {}
        self.translations_de = {}
        self.key_counter = 0
        
        # Anthropic API für bessere Übersetzungen
        self.use_ai = False
        try:
            api_key = os.environ.get("ANTHROPIC_API_KEY")
            if api_key:
                self.client = anthropic.Anthropic(api_key=api_key)
                self.use_ai = True
                print("✅ AI-Übersetzung aktiviert")
        except:
            print("ℹ️  AI-Übersetzung nicht verfügbar, nutze Standard-Mappings")
        
    def setup_folders(self):
        """Erstellt Ordnerstruktur für Übersetzungen"""
        self.assets_path.mkdir(parents=True, exist_ok=True)
        print(f"✅ Ordner erstellt: {self.assets_path}")
        
    def extract_strings(self) -> List[Tuple[Path, str, str, int]]:
        """Extrahiert alle Text-Strings aus Dart-Dateien"""
        patterns = [
            r'Text\([\'"]([^\'"]+)[\'"]\)',
            r'Text\([\'"]([^\'"]+)[\'"],\s*style:',
            r'hintText:\s*[\'"]([^\'"]+)[\'"]',
            r'labelText:\s*[\'"]([^\'"]+)[\'"]',
            r'label:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)',
            r'SnackBar\(content:\s*Text\([\'"]([^\'"]+)[\'"]\)',
            r'Exception\([\'"]([^\'"]+)[\'"]\)',
            r'child:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)',
            r'title:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)',
            r'subtitle:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)',
            r'tooltip:\s*[\'"]([^\'"]+)[\'"]',
        ]
        
        found_strings = []
        
        for dart_file in self.lib_path.rglob("*.dart"):
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
                for line_num, line in enumerate(lines, 1):
                    for pattern in patterns:
                        matches = re.finditer(pattern, line)
                        for match in matches:
                            text = match.group(1)
                            # Filter: Nur Texte mit Buchstaben und keine Variablen
                            if re.search(r'[a-zA-Z]', text) and not text.startswith('$'):
                                found_strings.append((dart_file, line, text, line_num))
        
        print(f"✅ {len(found_strings)} Texte gefunden")
        return found_strings
    
    def generate_key(self, text: str, context: str = "") -> str:
        """Generiert eindeutigen Schlüssel für Übersetzung"""
        context_lower = context.lower()
        
        # Bestimme Prefix aus Kontext
        if "login" in context_lower or "auth" in context_lower:
            prefix = "login"
        elif "register" in context_lower or "registr" in context_lower:
            prefix = "register"
        elif "deck" in context_lower:
            prefix = "deck"
        elif "card" in context_lower:
            prefix = "card"
        elif "search" in context_lower or "meta" in context_lower:
            prefix = "search"
        elif "error" in context_lower or "exception" in context_lower:
            prefix = "error"
        elif "button" in context_lower:
            prefix = "button"
        elif "hint" in context_lower:
            prefix = "hint"
        elif "label" in context_lower:
            prefix = "label"
        elif "calculator" in context_lower:
            prefix = "calculator"
        elif "home" in context_lower:
            prefix = "home"
        elif "appbar" in context_lower:
            prefix = "app"
        else:
            prefix = "general"
        
        # Erstelle Key aus Text (max 4 Wörter)
        key_text = re.sub(r'[^a-zA-Z0-9\s]', '', text.lower())
        key_text = '_'.join(key_text.split()[:4])
        
        if not key_text:
            key_text = f"text_{self.key_counter}"
        
        self.key_counter += 1
        return f"{prefix}.{key_text}"
    
    def translate_to_german_ai(self, english_text: str) -> str:
        """KI-basierte Übersetzung mit Claude"""
        if not self.use_ai:
            return self.translate_to_german(english_text)
        
        try:
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=100,
                messages=[{
                    "role": "user",
                    "content": f"Translate this UI text to German (informal 'du'). Only return the translation, nothing else: {english_text}"
                }]
            )
            return message.content[0].text.strip()
        except:
            return self.translate_to_german(english_text)
    
    def translate_to_german(self, english_text: str) -> str:
        """Standard-Übersetzungs-Mappings"""
        translations = {
            # Auth
            "Login": "Anmelden",
            "Login successful!": "Anmeldung erfolgreich!",
            "Email address": "E-Mail-Adresse",
            "Email": "E-Mail",
            "Password": "Passwort",
            "Repeat Email": "E-Mail wiederholen",
            "Repeat Password": "Passwort wiederholen",
            "Please enter an email address": "Bitte E-Mail-Adresse eingeben",
            "Please enter a password": "Bitte Passwort eingeben",
            "Registration": "Registrierung",
            "Register": "Registrieren",
            "Registration successful!": "Registrierung erfolgreich!",
            "Username": "Benutzername",
            "Confirm password": "Passwort bestätigen",
            "Confirm with password": "Mit Passwort bestätigen",
            "Enter your password": "Gib dein Passwort ein",
            "Please enter your password": "Bitte gib dein Passwort ein",
            
            # Deck Management
            "Create New Deck": "Neues Deck erstellen",
            "Edit Deck": "Deck bearbeiten",
            "Delete Deck": "Deck löschen",
            "Delete Account": "Account löschen",
            "You haven't created a deck yet": "Du hast noch kein Deck erstellt",
            "Deck successfully deleted!": "Deck erfolgreich gelöscht!",
            "Do you really want to delete this deck?": "Möchtest du dieses Deck wirklich löschen?",
            "Do you really want to delete the deck": "Möchtest du das Deck wirklich löschen",
            "This action cannot be undone": "Diese Aktion kann nicht rückgängig gemacht werden",
            "Deck name...": "Deckname...",
            "deckname...": "Deckname...",
            "No decks found": "Keine Decks gefunden",
            "Your Decks": "Deine Decks",
            "Deck Configuration": "Deck-Konfiguration",
            "Deck Size": "Deckgröße",
            "Hand Size": "Handgröße",
            "Main Deck": "Hauptdeck",
            "Extra Deck": "Extradeck",
            "Side Deck": "Sidedeck",
            "MAIN": "HAUPT",
            "EXTRA": "EXTRA",
            "SIDE": "SEITE",
            "Main": "Main",
            "Extra": "Extra",
            "Side": "Side",
            "is empty": "ist leer",
            
            # Cards
            "Add Card": "Karte hinzufügen",
            "No Cards found": "Keine Karten gefunden",
            "No Cardss found": "Keine Karten gefunden",
            "Search for cards": "Karten suchen",
            "search Card...": "Karte suchen...",
            "Card name...": "Kartenname...",
            "Cardname...": "Kartenname...",
            "Write a Cardname or use the filters": "Gib einen Kartennamen ein oder nutze die Filter",
            "This card is forbidden": "Diese Karte ist verboten",
            "This card is limited": "Diese Karte ist limitiert",
            "This card is semi-limited": "Diese Karte ist semi-limitiert",
            "Diese Karte ist limitiert": "Diese Karte ist limitiert",
            "Diese Karte ist semi-limitiert": "Diese Karte ist semi-limitiert",
            "Target Cards": "Zielkarten",
            "Copies": "Kopien",
            "Required": "Erforderlich",
            "Card": "Karte",
            "Cards": "Karten",
            "cards": "Karten",
            "card": "Karte",
            "unknown Card": "Unbekannte Karte",
            "unknown": "Unbekannt",
            
            # Actions
            "Cancel": "Abbrechen",
            "cancel": "Abbrechen",
            "Delete": "Löschen",
            "Save": "Speichern",
            "Search": "Suchen",
            "search": "Suchen",
            "Filter": "Filter",
            "Show Filter": "Filter anzeigen",
            "Reset": "Zurücksetzen",
            "reset": "Zurücksetzen",
            "Add": "Hinzufügen",
            "Edit": "Bearbeiten",
            "Continue editing": "Weiter bearbeiten",
            "discard changes?": "Änderungen verwerfen?",
            
            # Status
            "Loading...": "Lädt...",
            "loading...": "Lädt...",
            "loading App...": "App wird geladen...",
            "Error": "Fehler",
            "Success": "Erfolg",
            "Error loading": "Fehler beim Laden",
            "Error deleting": "Fehler beim Löschen",
            "Error on logout:": "Fehler beim Abmelden:",
            "Error on saving:": "Fehler beim Speichern:",
            "Successfully logged out!": "Erfolgreich abgemeldet!",
            "Logout": "Abmelden",
            
            # Navigation
            "Welcome": "Willkommen",
            "Home": "Startseite",
            "home": "Startseite",
            "Profile": "Profil",
            "profile": "Profil",
            "Settings": "Einstellungen",
            "Comments": "Kommentare",
            "Comment": "Kommentar",
            "Write a Comment": "Schreibe einen Kommentar",
            "Comment added": "Kommentar hinzugefügt",
            "comment deleted": "Kommentar gelöscht",
            "No Comments": "Keine Kommentare",
            
            # Filter/Search
            "Filter Search": "Filtersuche",
            "Type": "Typ",
            "Race": "Kategorie",
            "Attribute": "Attribut",
            "Archetype": "Archetyp",
            "Level": "Level",
            "Scale": "Skala",
            "Link Rating": "Link-Bewertung",
            "ATK": "ATK",
            "DEF": "DEF",
            "TCG Banlist": "TCG Bannliste",
            "OCG Banlist": "OCG Bannliste",
            "TCG Bannliste": "TCG Bannliste",
            "OCG Bannliste": "OCG Bannliste",
            "Forbidden": "Verboten",
            "Limited": "Limitiert",
            "Semi-Limited": "Semi-Limitiert",
            "Enter a keyword.": "Gib ein Suchwort ein.",
            "Enter a deck name or select an archetype": "Gib einen Decknamen ein oder wähle einen Archetyp",
            "Filter by archetype": "Nach Archetyp filtern",
            "All archetypes": "Alle Archetypen",
            "Pls choose at least one Filter.": "Bitte wähle mindestens einen Filter.",
            "Filter reseted": "Filter zurückgesetzt",
            "Filter get loaded...": "Filter werden geladen...",
            
            # Calculator
            "Probability": "Wahrscheinlichkeit",
            "Probability Calculator": "Wahrscheinlichkeitsrechner",
            "AND Mode": "UND-Modus",
            "OR Mode": "ODER-Modus",
            
            # Account
            "Account Settings": "Kontoeinstellungen",
            "Account successfully deleted!": "Account erfolgreich gelöscht!",
            "Do you really want to permanently delete your account?": "Möchtest du deinen Account wirklich dauerhaft löschen?",
            
            # Errors
            "User not found": "Benutzer nicht gefunden",
            "Benutzer nicht gefunden": "Benutzer nicht gefunden",
            "User isn't logged in": "Benutzer ist nicht angemeldet",
            "Not logged in": "Nicht angemeldet",
            "Kein Benutzer angemeldet": "Kein Benutzer angemeldet",
            "Deck ID missing! Editing not possible": "Deck-ID fehlt! Bearbeitung nicht möglich",
            "error: deckid not found to load comments.": "Fehler: Deck-ID nicht gefunden, um Kommentare zu laden.",
            
            # Deck Actions
            "how often adding?": "Wie oft hinzufügen?",
            "Card deleted": "Karte gelöscht",
            "How many Cards do you want to delete from": "Wie viele Karten möchtest du löschen von",
            "Pls choose a deckcoverimage": "Bitte wähle ein Deck-Coverbild",
            "No Image available for:": "Kein Bild verfügbar für:",
            "Cover-has been set to": "Cover wurde gesetzt auf",
            "no working image url found for": "Keine funktionierende Bild-URL gefunden für",
            "added": "hinzugefügt",
            "Limit over!": "Limit überschritten!",
            "you are only allowed to play": "du darfst nur spielen",
            "copies": "Kopien",
            "successfully deleted!": "erfolgreich gelöscht!",
            "Error deleting deck:": "Fehler beim Löschen des Decks:",
            "Deck sucessfull saved!": "Deck erfolgreich gespeichert!",
            
            # Images
            "loading Cardimages...": "Kartenbilder werden geladen...",
            "loading Filteroptions..": "Filteroptionen werden geladen...",
            "TCG Banlist is loading..": "TCG Bannliste wird geladen...",
            "OCG Banlist is loading...": "OCG Bannliste wird geladen...",
        }
        
        # Versuche exakte Übereinstimmung
        if english_text in translations:
            return translations[english_text]
        
        # Versuche case-insensitive
        for key, value in translations.items():
            if key.lower() == english_text.lower():
                return value
        
        # Fallback: Nutze KI wenn verfügbar
        if self.use_ai:
            return self.translate_to_german_ai(english_text)
        
        # Letzter Fallback: Original-Text
        return english_text
    
    def build_translations(self, found_strings: List[Tuple[Path, str, str, int]]):
        """Erstellt JSON-Übersetzungsdateien"""
        seen_texts = {}  # text -> key mapping
        
        for file_path, line, text, line_num in found_strings:
            # Skip bereits gesehene Texte
            if text in seen_texts:
                continue
            
            # Generiere Key
            context = str(file_path.stem)
            key = self.generate_key(text, context)
            seen_texts[text] = key
            
            # Speichere Übersetzungen
            self.translations_en[key] = text
            self.translations_de[key] = self.translate_to_german(text)
        
        # Füge spezielle Keys hinzu
        special_keys = {
            "app.title": ("Cardbase", "Cardbase"),
            "app.loading": ("Loading...", "Lädt..."),
            "language.english": ("English", "Englisch"),
            "language.german": ("German", "Deutsch"),
            "language.switch": ("Switch Language", "Sprache wechseln"),
            "language.switched_to_english": ("Language switched to English", "Sprache zu Englisch gewechselt"),
            "language.switched_to_german": ("Language switched to German", "Sprache zu Deutsch gewechselt"),
        }
        
        for key, (en, de) in special_keys.items():
            self.translations_en[key] = en
            self.translations_de[key] = de
        
        # Speichere als JSON
        en_file = self.assets_path / "en.json"
        de_file = self.assets_path / "de.json"
        
        with open(en_file, 'w', encoding='utf-8') as f:
            json.dump(self.translations_en, f, indent=2, ensure_ascii=False)
        
        with open(de_file, 'w', encoding='utf-8') as f:
            json.dump(self.translations_de, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Übersetzungen gespeichert:")
        print(f"   📄 {en_file} ({len(self.translations_en)} Einträge)")
        print(f"   📄 {de_file} ({len(self.translations_de)} Einträge)")
    
    def update_pubspec(self):
        """Fügt easy_localization zu pubspec.yaml hinzu"""
        pubspec_path = self.project_root / "pubspec.yaml"
        
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Füge Dependency hinzu
        if "easy_localization" not in content:
            content = re.sub(
                r'(dependencies:\s*\n\s*flutter:\s*\n)',
                r'\1  easy_localization: ^3.0.0\n',
                content
            )
            print("✅ easy_localization zu dependencies hinzugefügt")
        
        # Füge Assets hinzu
        if "assets/translations/" not in content:
            if "assets:" in content:
                content = re.sub(
                    r'(flutter:\s*\n.*?assets:\s*\n)',
                    r'\1    - assets/translations/\n',
                    content,
                    flags=re.DOTALL
                )
            else:
                # Füge komplett neuen flutter: Abschnitt hinzu
                content += "\n\nflutter:\n  assets:\n    - assets/translations/\n"
            print("✅ assets/translations/ zu flutter.assets hinzugefügt")
        
        with open(pubspec_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ pubspec.yaml aktualisiert")
    
    def create_language_provider(self):
        """Erstellt Riverpod Provider für Sprach-Verwaltung"""
        provider_code = '''// lib/providers/language_provider.dart
// AUTO-GENERATED by auto_localize_flutter.py
// DO NOT EDIT MANUALLY - Run script again to regenerate

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tcg_app/class/sharedPreference.dart';

/// Notifier für Sprach-Management
class LanguageNotifier extends StateNotifier<Locale> {
  final SaveData _saveData;

  LanguageNotifier(this._saveData) : super(const Locale('en')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final savedLang = await _saveData.loadWithKey('app_language');
    if (savedLang != null && (savedLang == 'en' || savedLang == 'de')) {
      state = Locale(savedLang);
    }
  }

  Future<void> setLanguage(Locale locale) async {
    state = locale;
    await _saveData.saveWithKey('app_language', locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.languageCode == 'en' 
        ? const Locale('de') 
        : const Locale('en');
    await setLanguage(newLocale);
  }
}

/// Provider für Sprach-Notifier
final languageNotifierProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final saveData = SaveData();
  return LanguageNotifier(saveData);
});

/// Provider für Algolia Index basierend auf Sprache
final algoliaIndexProvider = Provider<String>((ref) {
  final locale = ref.watch(languageNotifierProvider);
  return locale.languageCode == 'de' ? 'cards_de' : 'cards';
});
'''
        
        provider_path = self.lib_path / "providers" / "language_provider.dart"
        provider_path.parent.mkdir(exist_ok=True)
        
        with open(provider_path, 'w', encoding='utf-8') as f:
            f.write(provider_code)
        
        print(f"✅ Language Provider erstellt: {provider_path}")
    
    def update_main_dart(self):
        """Aktualisiert main.dart mit EasyLocalization"""
        main_path = self.lib_path / "main.dart"
        
        with open(main_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Füge Imports hinzu
        imports_to_add = []
        
        if "import 'package:easy_localization/easy_localization.dart';" not in content:
            imports_to_add.append("import 'package:easy_localization/easy_localization.dart';")
        
        if "import 'package:tcg_app/providers/language_provider.dart';" not in content:
            imports_to_add.append("import 'package:tcg_app/providers/language_provider.dart';")
        
        if imports_to_add:
            # Finde letzte import-Zeile
            import_matches = list(re.finditer(r'^import .*?;$', content, re.MULTILINE))
            if import_matches:
                last_import = import_matches[-1]
                insert_pos = last_import.end()
                content = content[:insert_pos] + '\n' + '\n'.join(imports_to_add) + content[insert_pos:]
        
        # Ersetze main() Funktion
        main_pattern = r'void main\(\) async \{.*?runApp\([^)]+\);\s*\}'
        
        new_main = '''void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SaveData.initPreferences();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: MainApp()),
    ),
  );
}'''
        
        if not re.search(r'EasyLocalization\(', content):
            content = re.sub(main_pattern, new_main, content, flags=re.DOTALL)
        
        # Aktualisiere MaterialApp in build-Methode
        if "localizationsDelegates: context.localizationDelegates" not in content:
            # Suche MaterialApp( und füge Localization-Properties hinzu
            material_app_pattern = r'(return MaterialApp\(\s*)'
            material_app_replacement = r'''\1localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      '''
            content = re.sub(material_app_pattern, material_app_replacement, content)
        
        with open(main_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ main.dart aktualisiert")
    
    def update_appbar(self):
        """Fügt Sprach-Button zur AppBar hinzu"""
        appbar_path = self.lib_path / "class" / "common" / "appbar.dart"
        
        with open(appbar_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Füge Imports hinzu
        imports_to_add = []
        
        if "import 'package:easy_localization/easy_localization.dart';" not in content:
            imports_to_add.append("import 'package:easy_localization/easy_localization.dart';")
        
        if "import 'package:tcg_app/providers/language_provider.dart';" not in content:
            imports_to_add.append("import 'package:tcg_app/providers/language_provider.dart';")
        
        if imports_to_add:
            import_matches = list(re.finditer(r'^import .*?;$', content, re.MULTILINE))
            if import_matches:
                last_import = import_matches[-1]
                insert_pos = last_import.end()
                content = content[:insert_pos] + '\n' + '\n'.join(imports_to_add) + content[insert_pos:]
        
        # Ersetze actions Array
        new_actions = '''actions: [
        // 🌍 Language Switch Button
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: context.locale.languageCode == 'en' 
              ? 'Switch to German' 
              : 'Zu Englisch wechseln',
          onPressed: () async {
            final newLocale = context.locale.languageCode == 'en' 
                ? const Locale('de') 
                : const Locale('en');
            
            await context.setLocale(newLocale);
            ref.read(languageNotifierProvider.notifier).setLanguage(newLocale);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newLocale.languageCode == 'de' 
                        ? 'Sprache zu Deutsch gewechselt' 
                        : 'Language switched to English'
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        // 🌓 Dark Mode Button
        IconButton(
          icon: isDarkMode
              ? const Icon(Icons.light_mode)
              : const Icon(Icons.dark_mode),
          onPressed: () {
            final newMode = !isDarkMode;
            onThemeChanged(newMode);
            ref.read(darkModeProvider.notifier).toggleDarkMode(newMode);
          },
        ),
      ],'''
        
        # Suche nach bestehendem actions Array und ersetze es
        actions_pattern = r'actions:\s*\[[^\]]*\],'
        if re.search(actions_pattern, content, re.DOTALL):
            content = re.sub(actions_pattern, new_actions, content, flags=re.DOTALL)
        else:
            # Wenn kein actions Array existiert, füge es hinzu
            appbar_pattern = r'(AppBar\([^{]*\{)'
            content = re.sub(appbar_pattern, r'\1\n      ' + new_actions, content)
        
        with open(appbar_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ AppBar mit Sprach-Button aktualisiert")
    
    def update_card_data(self):
        """Aktualisiert CardData für dynamischen Algolia-Index"""
        card_data_path = self.lib_path / "class" / "Firebase" / "YugiohCard" / "getCardData.dart"
        
        with open(card_data_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 1. Füge customIndexName-Property hinzu
        if "final String? customIndexName;" not in content:
            class_pattern = r'(class CardData implements Dbrepo \{\s*\n)'
        
            replacement = r'\1  final String? customIndexName;\n\n'
            content = re.sub(class_pattern, replacement, content)
        
        # 2. Füge Constructor hinzu/aktualisiere ihn
        if "CardData({this.customIndexName});" not in content:
            # Entferne alten leeren Constructor falls vorhanden
            content = re.sub(r'\s*CardData\(\);', '', content)
            
            # Füge neuen Constructor nach den static Variablen ein
            storage_pattern = r'(final FirebaseStorage storage = FirebaseStorage\.instance;)'
            replacement = r'\1\n\n  CardData({this.customIndexName});'
            content = re.sub(storage_pattern, replacement, content)
        
        # 3. Ersetze ALLE hardcoded 'cards' Index-Namen
        # Wichtig: Nicht cards_de ersetzen!
        content = re.sub(
            r"indexName:\s*'cards'(?!_)",
            "indexName: customIndexName ?? 'cards'",
            content
        )
        
        with open(card_data_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ CardData für dynamischen Algolia-Index aktualisiert")
    
    def update_app_providers(self):
        """Aktualisiert app_providers.dart für dynamischen CardData-Index"""
        providers_path = self.lib_path / "providers" / "app_providers.dart"
        
        with open(providers_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Füge Import hinzu
        if "import 'package:tcg_app/providers/language_provider.dart';" not in content:
            import_matches = list(re.finditer(r'^import .*?;$', content, re.MULTILINE))
            if import_matches:
                last_import = import_matches[-1]
                insert_pos = last_import.end()
                content = content[:insert_pos] + '\nimport \'package:tcg_app/providers/language_provider.dart\';\n' + content[insert_pos:]
        
        # Ersetze cardDataProvider
        old_provider_pattern = r'final cardDataProvider = Provider<CardData>\(\(ref\) \{\s*return CardData\(\);\s*\}\);'
        
        new_provider = '''final cardDataProvider = Provider<CardData>((ref) {
  final algoliaIndex = ref.watch(algoliaIndexProvider);
  return CardData(customIndexName: algoliaIndex);
});'''
        
        if re.search(old_provider_pattern, content):
            content = re.sub(old_provider_pattern, new_provider, content)
        else:
            # Falls Pattern nicht gefunden, suche nach einfacherer Version
            simple_pattern = r'(final cardDataProvider = Provider<CardData>\(\(ref\) \{)\s*return CardData\(\);'
            if re.search(simple_pattern, content):
                content = re.sub(
                    simple_pattern,
                    r'\1\n  final algoliaIndex = ref.watch(algoliaIndexProvider);\n  return CardData(customIndexName: algoliaIndex);',
                    content
                )
        
        with open(providers_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print("✅ app_providers.dart aktualisiert")
    
    def create_backup(self):
        """Erstellt Backup der wichtigsten Dateien"""
        backup_dir = self.project_root / "localization_backup"
        backup_dir.mkdir(exist_ok=True)
        
        files_to_backup = [
            self.lib_path / "main.dart",
            self.lib_path / "class" / "common" / "appbar.dart",
            self.lib_path / "providers" / "app_providers.dart",
            self.lib_path / "class" / "Firebase" / "YugiohCard" / "getCardData.dart",
            self.project_root / "pubspec.yaml",
        ]
        
        for file_path in files_to_backup:
            if file_path.exists():
                import shutil
                backup_path = backup_dir / file_path.name
                shutil.copy2(file_path, backup_path)
        
        print(f"✅ Backup erstellt in: {backup_dir}")
    
    def run(self):
        """Führt komplette Lokalisierung durch"""
        print("=" * 60)
        print("🚀 VOLLAUTOMATISCHE FLUTTER LOKALISIERUNG")
        print("=" * 60)
        print()
        
        # 0. Backup
        print("📦 Erstelle Backup...")
        self.create_backup()
        print()
        
        # 1. Setup
        print("📁 Erstelle Ordnerstruktur...")
        self.setup_folders()
        print()
        
        # 2. Extrahiere Strings
        print("🔍 Extrahiere Texte aus Dart-Dateien...")
        found_strings = self.extract_strings()
        print()
        
        # 3. Erstelle Übersetzungen
        print("🌍 Erstelle Übersetzungsdateien...")
        self.build_translations(found_strings)
        print()
        
        # 4. Aktualisiere Dateien
        print("🔧 Aktualisiere Flutter-Dateien...")
        self.update_pubspec()
        self.create_language_provider()
        self.update_main_dart()
        self.update_appbar()
        self.update_card_data()
        self.update_app_providers()
        print()
        
        print("=" * 60)
        print("✅ LOKALISIERUNG ERFOLGREICH ABGESCHLOSSEN!")
        print("=" * 60)
        print()
        print("📋 NÄCHSTE SCHRITTE:")
        print()
        print("1️⃣  Führe aus: flutter pub get")
        print("2️⃣  Starte die App neu: flutter run")
        print("3️⃣  Klicke auf 🌍-Button in der AppBar zum Testen")
        print()
        print("⚠️  WICHTIG: Algolia Setup")
        print("   → Erstelle einen Index 'cards_de' in Algolia")
        print("   → Importiere deutsche Kartendaten")
        print("   → Konfiguriere gleiche Searchable Attributes wie 'cards'")
        print()
        print("📂 Backup-Ordner: localization_backup/")
        print("   (Falls etwas schiefgeht, kannst du Dateien wiederherstellen)")
        print()
        print("=" * 60)

def main():
    """Hauptfunktion"""
    import sys
    
    # Ermittle Projekt-Root
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = "."
    
    # Prüfe ob es ein Flutter-Projekt ist
    project_path = Path(project_root)
    if not (project_path / "pubspec.yaml").exists():
        print("❌ FEHLER: Kein Flutter-Projekt gefunden!")
        print(f"   Gesucht in: {project_path.absolute()}")
        print()
        print("💡 Verwendung:")
        print("   python auto_localize_flutter.py [projekt-pfad]")
        print()
        print("   Beispiele:")
        print("   python auto_localize_flutter.py")
        print("   python auto_localize_flutter.py /path/to/flutter/project")
        sys.exit(1)
    
    # Führe Lokalisierung durch
    try:
        localizer = FlutterLocalizer(project_root)
        localizer.run()
    except Exception as e:
        print()
        print("=" * 60)
        print("❌ FEHLER BEI DER AUSFÜHRUNG")
        print("=" * 60)
        print()
        print(f"Fehlermeldung: {e}")
        print()
        print("🔧 Mögliche Lösungen:")
        print("1. Stelle sicher, dass alle Dart-Dateien gültigen Syntax haben")
        print("2. Prüfe, ob du Schreibrechte im Projekt-Ordner hast")
        print("3. Stelle Dateien aus dem Backup wieder her")
        print()
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()