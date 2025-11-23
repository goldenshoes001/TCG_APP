#!/usr/bin/env python3
"""
EINFACHE MANUELLE KORREKTUREN
"""

import os

def apply_final_fixes():
    """Wendet die endgültigen Korrekturen an"""
    
    fixes = [
        # login.dart - .tr zu .tr()
        {
            'file': 'lib/class/Firebase/user/login.dart',
            'old': 'labelText: "login.passwort".tr,',
            'new': 'labelText: "login.passwort".tr(),'
        },
        {
            'file': 'lib/class/Firebase/user/login.dart',
            'old': 'hintText: "login.passwort".tr,', 
            'new': 'hintText: "login.passwort".tr(),'
        },
        # registrieren.dart - .tr zu .tr()
        {
            'file': 'lib/class/Firebase/user/registrieren.dart',
            'old': 'labelText: "login.username".tr,',
            'new': 'labelText: "login.username".tr(),'
        },
        {
            'file': 'lib/class/Firebase/user/registrieren.dart',
            'old': 'hintText: "login.username".tr,',
            'new': 'hintText: "login.username".tr(),'
        },
        # Weitere registrieren.dart fixes...
    ]
    
    # Füge alle registrieren.dart fixes hinzu
    registrieren_fixes = [
        'labelText: "register.email".tr,',
        'hintText: "register.email".tr,',
        'labelText: "register.repeat_email".tr,',
        'hintText: "register.repeat_email".tr,', 
        'labelText: "register.password".tr,',
        'hintText: "register.password".tr,',
        'labelText: "register.repeat_password".tr,',
        'hintText: "register.repeat_password".tr,'
    ]
    
    for fix in registrieren_fixes:
        fixes.append({
            'file': 'lib/class/Firebase/user/registrieren.dart',
            'old': fix,
            'new': fix.replace('.tr,', '.tr(),')
        })
    
    for fix in fixes:
        file_path = os.path.join(os.getcwd(), fix['file'])
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            if fix['old'] in content:
                content = content.replace(fix['old'], fix['new'])
                with open(file_path, 'w', encoding='utf-8') as file:
                    file.write(content)
                print(f"✅ Behoben: {fix['file']} - {fix['old']}")
            else:
                print(f"⚠️ Nicht gefunden: {fix['file']} - {fix['old']}")
        else:
            print(f"❌ Datei nicht gefunden: {file_path}")

if __name__ == "__main__":
    apply_final_fixes()