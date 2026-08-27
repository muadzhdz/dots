#!/usr/bin/env python3
import sys, os, json, shutil

mode = sys.argv[1] if len(sys.argv) > 1 else "dark"
is_dark = (mode == "dark")
chromium_scheme = 1 if is_dark else 2
ff_override = 0 if is_dark else 1

themes_dir = os.path.expanduser('~/.config/themes')
browser_chrome_css = os.path.join(themes_dir, mode, 'browser-userchrome.css')
browser_content_css = os.path.join(themes_dir, mode, 'browser-usercontent.css')

# 1. Update Chromium / Chrome / Helium / Brave Preferences
for pref_path in [
    os.path.expanduser('~/.config/chromium/Default/Preferences'),
    os.path.expanduser('~/.config/google-chrome/Default/Preferences'),
    os.path.expanduser('~/.config/BraveSoftware/Brave-Browser/Default/Preferences'),
    os.path.expanduser('~/.config/helium/Default/Preferences')
]:
    if os.path.exists(pref_path):
        try:
            with open(pref_path, 'r') as f:
                data = json.load(f)
            data.setdefault('browser', {}).setdefault('theme', {})
            data['browser']['theme']['follows_system_colors'] = True
            data['browser']['theme']['color_scheme2'] = chromium_scheme
            if 'extensions' in data and 'theme' in data['extensions']:
                data['extensions']['theme'] = {'id': '', 'system_theme': 1}
            with open(pref_path, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass

# 2. Update Firefox & Zen across all profiles
profile_dirs = []
for base in ['~/.mozilla/firefox', '~/.config/mozilla/firefox', '~/.zen', '~/.config/zen']:
    expanded = os.path.expanduser(base)
    if os.path.isdir(expanded):
        for entry in os.listdir(expanded):
            full_path = os.path.join(expanded, entry)
            if os.path.isdir(full_path) and entry not in ['Crash Reports', 'Pending Pings', 'Profile Groups', 'Pending Deletes']:
                profile_dirs.append(full_path)

for profile_dir in profile_dirs:
    # Deploy user.js
    user_js = os.path.join(profile_dir, 'user.js')
    try:
        lines = []
        if os.path.exists(user_js):
            with open(user_js, 'r') as f:
                lines = [l for l in f.readlines() if not any(k in l for k in [
                    'layout.css.prefers-color-scheme.content-override',
                    'ui.systemUsesDarkTheme',
                    'browser.theme.toolbar-theme',
                    'browser.theme.content-theme',
                    'toolkit.legacyUserProfileCustomizations.stylesheets'
                ])]
        lines.append('user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n')
        lines.append(f'user_pref("layout.css.prefers-color-scheme.content-override", {ff_override});\n')
        lines.append(f'user_pref("ui.systemUsesDarkTheme", {1 if is_dark else 0});\n')
        lines.append(f'user_pref("browser.theme.toolbar-theme", {0 if is_dark else 1});\n')
        lines.append(f'user_pref("browser.theme.content-theme", {0 if is_dark else 1});\n')
        with open(user_js, 'w') as f:
            f.writelines(lines)
    except Exception:
        pass

    # Deploy userChrome.css and userContent.css
    chrome_dir = os.path.join(profile_dir, 'chrome')
    try:
        os.makedirs(chrome_dir, exist_ok=True)
        if os.path.exists(browser_chrome_css):
            shutil.copy(browser_chrome_css, os.path.join(chrome_dir, 'userChrome.css'))
        if os.path.exists(browser_content_css):
            shutil.copy(browser_content_css, os.path.join(chrome_dir, 'userContent.css'))
    except Exception:
        pass

print(f"Synced {len(profile_dirs)} profiles for mode: {mode}")
