#!/usr/bin/env python3
"""
🔧 Automatisches .tr() Hinzufügen für Flutter EasyLocalization
Ergänzung zu auto_localize_flutter.py

Features:
✅ Lädt bestehende JSON-Übersetzungen
✅ Findet alle hardcoded Strings in Dart-Dateien
✅ Ersetzt automatisch mit .tr() Aufrufen
✅ Fügt import für easy_localization hinzu
✅ Erstellt Backup vor Änderungen
✅ Zeigt Vorschau der Änderungen

Verwendung:
    python auto_add_tr.py [--dry-run] [--file path/to/file.dart]
"""

import os
import re
import json
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Set
import argparse
from datetime import datetime

class TrAdder:
    def __init__(self, project_root: str, dry_run: bool = False):
        self.project_root = Path(project_root)
        self.lib_path = self.project_root / "lib"
        self.translations_path = self.project_root / "assets" / "translations"
        self.dry_run = dry_run
        
        # Lade bestehende Übersetzungen
        self.translations_en = {}
        self.translations_de = {}
        self.text_to_key = {}  # Mapping von Text -> Key
        
        self._load_translations()
        
        # Statistiken
        self.files_modified = 0
        self.strings_replaced = 0
        self.files_skipped = 0
        
    def _load_translations(self):
        """Lädt bestehende JSON-Übersetzungen"""
        en_file = self.translations_path / "en.json"
        de_file = self.translations_path / "de.json"
        
        if not en_file.exists():
            print(f"❌ Keine Übersetzungen gefunden in {self.translations_path}")
            print("   Führe erst auto_localize_flutter.py aus!")
            exit(1)
        
        with open(en_file, 'r', encoding='utf-8') as f:
            self.translations_en = json.load(f)
        
        with open(de_file, 'r', encoding='utf-8') as f:
            self.translations_de = json.load(f)
        
        # Erstelle Reverse-Mapping (Text -> Key)
        for key, text in self.translations_en.items():
            # Normalisiere Text für besseres Matching
            normalized = text.strip().lower()
            self.text_to_key[normalized] = key
            # Speichere auch Original für case-sensitive Matches
            self.text_to_key[text.strip()] = key
        
        print(f"✅ {len(self.translations_en)} Übersetzungen geladen")
    
    def _find_key_for_text(self, text: str) -> str:
        """Findet den passenden Translation-Key für einen Text"""
        text_stripped = text.strip()
        
        # Exakte Übereinstimmung
        if text_stripped in self.text_to_key:
            return self.text_to_key[text_stripped]
        
        # Case-insensitive
        text_lower = text_stripped.lower()
        if text_lower in self.text_to_key:
            return self.text_to_key[text_lower]
        
        # Versuche ohne Satzzeichen am Ende
        text_no_punct = text_stripped.rstrip('.!?:,;')
        if text_no_punct in self.text_to_key:
            return self.text_to_key[text_no_punct]
        
        text_no_punct_lower = text_no_punct.lower()
        if text_no_punct_lower in self.text_to_key:
            return self.text_to_key[text_no_punct_lower]
        
        # Kein Key gefunden - nutze Text selbst
        return None
    
    def _should_skip_file(self, file_path: Path) -> bool:
        """Prüft ob Datei übersprungen werden soll"""
        skip_patterns = [
            "*.g.dart",  # Generated files
            "*.freezed.dart",
            "firebase_options.dart",
            "language_provider.dart",  # Schon korrekt
        ]
        
        for pattern in skip_patterns:
            if file_path.match(pattern):
                return True
        
        return False
    
    def _needs_import(self, content: str) -> bool:
        """Prüft ob easy_localization Import fehlt"""
        return "import 'package:easy_localization/easy_localization.dart';" not in content
    
    def _add_import(self, content: str) -> str:
        """Fügt easy_localization Import hinzu"""
        if not self._needs_import(content):
            return content
        
        # Finde letzte import-Zeile
        import_matches = list(re.finditer(r'^import .*?;$', content, re.MULTILINE))
        
        if import_matches:
            last_import = import_matches[-1]
            insert_pos = last_import.end()
            return (content[:insert_pos] + 
                    "\nimport 'package:easy_localization/easy_localization.dart';" + 
                    content[insert_pos:])
        else:
            # Keine imports gefunden, füge am Anfang ein
            return "import 'package:easy_localization/easy_localization.dart';\n\n" + content
    
    def _replace_strings_in_line(self, line: str, line_num: int) -> Tuple[str, List[str]]:
        """Ersetzt Strings in einer Zeile mit .tr() Aufrufen"""
        changes = []
        
        # Patterns für verschiedene String-Kontexte
        patterns = [
            # Text Widget: Text("string") -> Text("key".tr())
            (r'Text\([\'"]([^\'"]+)[\'"]\)', r'Text("\1".tr())'),
            
            # Text mit Style: Text("string", style:...) -> Text("key".tr(), style:...)
            (r'Text\([\'"]([^\'"]+)[\'"],\s*style:', r'Text("\1".tr(), style:'),
            
            # Label: label: Text("string") -> label: Text("key".tr())
            (r'label:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)', r'label: Text("\1".tr())'),
            
            # HintText: hintText: "string" -> hintText: "key".tr()
            (r'hintText:\s*[\'"]([^\'"]+)[\'"]', r'hintText: "\1".tr()'),
            
            # LabelText: labelText: "string" -> labelText: "key".tr()
            (r'labelText:\s*[\'"]([^\'"]+)[\'"]', r'labelText: "\1".tr()'),
            
            # Tooltip: tooltip: "string" -> tooltip: "key".tr()
            (r'tooltip:\s*[\'"]([^\'"]+)[\'"]', r'tooltip: "\1".tr()'),
            
            # SnackBar: SnackBar(content: Text("string")) -> SnackBar(content: Text("key".tr()))
            (r'SnackBar\(content:\s*Text\([\'"]([^\'"]+)[\'"]\)', r'SnackBar(content: Text("\1".tr())'),
            
            # Child Text: child: Text("string") -> child: Text("key".tr())
            (r'child:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)', r'child: Text("\1".tr())'),
            
            # Title/Subtitle: title: Text("string") -> title: Text("key".tr())
            (r'title:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)', r'title: Text("\1".tr())'),
            (r'subtitle:\s*(?:const\s+)?Text\([\'"]([^\'"]+)[\'"]\)', r'subtitle: Text("\1".tr())'),
        ]
        
        modified_line = line
        
        for pattern, replacement in patterns:
            matches = list(re.finditer(pattern, modified_line))
            
            for match in reversed(matches):  # Rückwärts um Indizes nicht zu verschieben
                original_text = match.group(1)
                
                # Skip wenn bereits .tr() vorhanden
                if '.tr()' in match.group(0):
                    continue
                
                # Skip wenn es wie ein Variablenname aussieht
                if original_text.startswith('$') or not re.search(r'[a-zA-Z]', original_text):
                    continue
                
                # Finde passenden Key
                key = self._find_key_for_text(original_text)
                
                if key:
                    # Ersetze Text mit Key
                    new_replacement = replacement.replace(r'\1', key)
                    modified_line = modified_line[:match.start()] + re.sub(pattern, new_replacement, match.group(0)) + modified_line[match.end():]
                    changes.append(f"  Line {line_num}: '{original_text}' -> '{key}'.tr()")
        
        return modified_line, changes
    
    def process_file(self, file_path: Path) -> bool:
        """Verarbeitet eine einzelne Dart-Datei"""
        if self._should_skip_file(file_path):
            return False
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
        except Exception as e:
            print(f"⚠️  Fehler beim Lesen von {file_path}: {e}")
            return False
        
        # Prüfe ob Datei bereits .tr() verwendet
        if '.tr()' in original_content:
            # Datei verwendet bereits Übersetzungen
            return False
        
        # Verarbeite Zeile für Zeile
        lines = original_content.split('\n')
        modified_lines = []
        all_changes = []
        has_changes = False
        
        for line_num, line in enumerate(lines, 1):
            modified_line, changes = self._replace_strings_in_line(line, line_num)
            
            if changes:
                has_changes = True
                all_changes.extend(changes)
            
            modified_lines.append(modified_line)
        
        if not has_changes:
            return False
        
        # Füge Import hinzu wenn nötig
        modified_content = '\n'.join(modified_lines)
        if self._needs_import(modified_content):
            modified_content = self._add_import(modified_content)
            all_changes.insert(0, f"  ✅ Import hinzugefügt: easy_localization")
        
        # Zeige Änderungen
        rel_path = file_path.relative_to(self.lib_path)
        print(f"\n📝 {rel_path}")
        for change in all_changes[:10]:  # Zeige max 10 Änderungen
            print(change)
        if len(all_changes) > 10:
            print(f"  ... und {len(all_changes) - 10} weitere Änderungen")
        
        # Speichere wenn nicht Dry-Run
        if not self.dry_run:
            # Erstelle Backup
            backup_path = file_path.with_suffix('.dart.bak')
            shutil.copy2(file_path, backup_path)
            
            # Schreibe modifizierte Datei
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(modified_content)
        
        self.strings_replaced += len(all_changes)
        return True
    
    def process_directory(self, directory: Path = None):
        """Verarbeitet alle Dart-Dateien in einem Verzeichnis"""
        if directory is None:
            directory = self.lib_path
        
        dart_files = list(directory.rglob("*.dart"))
        total_files = len(dart_files)
        
        print(f"\n🔍 Durchsuche {total_files} Dart-Dateien...\n")
        
        for i, file_path in enumerate(dart_files, 1):
            if self.process_file(file_path):
                self.files_modified += 1
            else:
                self.files_skipped += 1
            
            # Fortschritt
            if i % 10 == 0:
                print(f"   Fortschritt: {i}/{total_files} Dateien")
        
    def create_backup(self):
        """Erstellt vollständiges Backup"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = self.project_root / f"backup_before_tr_{timestamp}"
        backup_dir.mkdir(exist_ok=True)
        
        # Kopiere lib Ordner
        lib_backup = backup_dir / "lib"
        shutil.copytree(self.lib_path, lib_backup, dirs_exist_ok=True)
        
        print(f"✅ Vollständiges Backup erstellt: {backup_dir}")
        return backup_dir
    
    def run(self):
        """Führt kompletten Prozess aus"""
        print("=" * 70)
        print("🔧 AUTOMATISCHES .tr() HINZUFÜGEN")
        print("=" * 70)
        
        if self.dry_run:
            print("\n⚠️  DRY-RUN MODUS - Keine Dateien werden geändert\n")
        else:
            print("\n📦 Erstelle Backup...")
            backup_dir = self.create_backup()
            print()
        
        # Verarbeite alle Dateien
        self.process_directory()
        
        # Statistiken
        print("\n" + "=" * 70)
        print("📊 STATISTIKEN")
        print("=" * 70)
        print(f"✅ Dateien geändert:      {self.files_modified}")
        print(f"⏭️  Dateien übersprungen:  {self.files_skipped}")
        print(f"🔄 Strings ersetzt:       {self.strings_replaced}")
        print("=" * 70)
        
        if not self.dry_run and self.files_modified > 0:
            print("\n✅ ERFOLGREICH ABGESCHLOSSEN!")
            print()
            print("📋 NÄCHSTE SCHRITTE:")
            print("1️⃣  Führe aus: flutter pub get")
            print("2️⃣  Teste die App: flutter run")
            print("3️⃣  Klicke auf 🌍-Button zum Testen")
            print()
            print("⚠️  Falls etwas schiefgeht:")
            print(f"   Stelle Dateien aus {backup_dir} wieder her")
            print("   Oder nutze die .bak Dateien neben den geänderten Dateien")
        elif self.dry_run:
            print("\n✅ DRY-RUN ABGESCHLOSSEN")
            print("   Führe ohne --dry-run aus um Änderungen anzuwenden")
        else:
            print("\n⚠️  Keine Änderungen vorgenommen")
            print("   Mögliche Gründe:")
            print("   - Alle Strings verwenden bereits .tr()")
            print("   - Keine übersetzten Strings in JSON gefunden")
            print("   - Falsche Projekt-Struktur")

def main():
    parser = argparse.ArgumentParser(
        description="Fügt automatisch .tr() zu allen Strings in Flutter-Projekt hinzu"
    )
    parser.add_argument(
        "project_root",
        nargs="?",
        default=".",
        help="Pfad zum Flutter-Projekt (Standard: aktuelles Verzeichnis)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Zeigt nur Änderungen an, ohne Dateien zu modifizieren"
    )
    parser.add_argument(
        "--file",
        help="Verarbeite nur eine bestimmte Datei"
    )
    
    args = parser.parse_args()
    
    # Prüfe ob Flutter-Projekt
    project_path = Path(args.project_root)
    if not (project_path / "pubspec.yaml").exists():
        print("❌ FEHLER: Kein Flutter-Projekt gefunden!")
        print(f"   Gesucht in: {project_path.absolute()}")
        exit(1)
    
    # Prüfe ob Übersetzungen existieren
    translations_path = project_path / "assets" / "translations"
    if not translations_path.exists() or not (translations_path / "en.json").exists():
        print("❌ FEHLER: Keine Übersetzungsdateien gefunden!")
        print(f"   Gesucht in: {translations_path}")
        print()
        print("💡 Führe erst auto_localize_flutter.py aus!")
        exit(1)
    
    try:
        adder = TrAdder(args.project_root, dry_run=args.dry_run)
        
        if args.file:
            # Verarbeite einzelne Datei
            file_path = Path(args.file)
            if not file_path.exists():
                print(f"❌ Datei nicht gefunden: {file_path}")
                exit(1)
            
            print(f"📝 Verarbeite einzelne Datei: {file_path}")
            adder.process_file(file_path)
        else:
            # Verarbeite ganzes Projekt
            adder.run()
            
    except KeyboardInterrupt:
        print("\n\n⚠️  Abgebrochen durch Benutzer")
        exit(1)
    except Exception as e:
        print(f"\n❌ FEHLER: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

if __name__ == "__main__":
    main()