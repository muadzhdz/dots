#!/usr/bin/env python3
import os
import sys
import glob
import re
import subprocess

def get_current_default():
    try:
        res = subprocess.run(['xdg-settings', 'get', 'default-web-browser'], capture_output=True, text=True)
        out = res.stdout.strip()
        if out:
            return out
    except Exception:
        pass
    try:
        res = subprocess.run(['xdg-mime', 'query', 'default', 'x-scheme-handler/https'], capture_output=True, text=True)
        out = res.stdout.strip()
        if out:
            return out
    except Exception:
        pass
    return "firefox.desktop"

def get_installed_browsers():
    desktop_dirs = [
        '/usr/share/applications',
        '/usr/local/share/applications',
        os.path.expanduser('~/.local/share/applications')
    ]
    browsers = {}
    known_targets = {
        'firefox.desktop': ('Firefox', '󰈹', 'firefox'),
        'chromium.desktop': ('Chromium', '', 'chromium'),
        'zen.desktop': ('Zen Browser', '󰈹', 'zen-bin'),
        'zen-browser.desktop': ('Zen Browser', '󰈹', 'zen-bin'),
        'helium-browser.desktop': ('Helium Browser', '󰈹', 'helium-browser'),
        'brave-browser.desktop': ('Brave', '󰈹', 'brave-browser'),
        'google-chrome.desktop': ('Google Chrome', '', 'google-chrome')
    }

    for d in desktop_dirs:
        if not os.path.exists(d):
            continue
        for f in glob.glob(os.path.join(d, '*.desktop')):
            bname = os.path.basename(f)
            if bname in known_targets:
                display_name, icon, binary = known_targets[bname]
                browsers[bname] = {
                    'name': display_name,
                    'icon': icon,
                    'binary': binary,
                    'desktop': bname
                }
            else:
                if any(b in bname.lower() for b in ['firefox', 'chromium', 'zen', 'brave', 'chrome', 'helium']):
                    try:
                        with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
                            content = fp.read()
                            name_match = re.search(r'^Name=(.+)$', content, re.MULTILINE)
                            if name_match:
                                display_name = name_match.group(1).strip()
                                icon = '' if 'chrome' in display_name.lower() or 'chromium' in display_name.lower() else '󰈹'
                                binary = bname.replace('.desktop', '')
                                browsers[bname] = {
                                    'name': display_name,
                                    'icon': icon,
                                    'binary': binary,
                                    'desktop': bname
                                }
                    except Exception:
                        pass
    return browsers

current_default = get_current_default()
browsers = get_installed_browsers()

if not browsers:
    sys.exit(0)

options = []
desktop_map = {}

for bname, info in browsers.items():
    is_active = (bname == current_default)
    label = f"{info['icon']}  {info['name']}" + (" (Default)" if is_active else "")
    options.append(label)
    desktop_map[label] = info

rofi_cmd = [
    'rofi', '-dmenu', '-i',
    '-p', 'Default Browser:'
]

proc = subprocess.Popen(rofi_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
stdout, _ = proc.communicate(input='\n'.join(options))

selected_label = stdout.strip()
if not selected_label or selected_label not in desktop_map:
    sys.exit(0)

chosen = desktop_map[selected_label]
target_desktop = chosen['desktop']
target_binary = chosen['binary']
target_name = chosen['name']

subprocess.run(['xdg-settings', 'set', 'default-web-browser', target_desktop], capture_output=True)

mime_types = [
    'x-scheme-handler/http',
    'x-scheme-handler/https',
    'x-scheme-handler/about',
    'x-scheme-handler/unknown',
    'text/html'
]
for m in mime_types:
    subprocess.run(['xdg-mime', 'default', target_desktop, m], capture_output=True)

mimeapps_path = os.path.expanduser('~/.config/mimeapps.list')
if os.path.exists(mimeapps_path):
    with open(mimeapps_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    in_default_sec = False

    for line in lines:
        if line.strip() == '[Default Applications]':
            in_default_sec = True
            new_lines.append(line)
            for m in mime_types:
                new_lines.append(f'{m}={target_desktop}\n')
            continue
        elif line.startswith('[') and line.strip() != '[Default Applications]':
            in_default_sec = False
        
        if in_default_sec:
            key = line.split('=')[0].strip() if '=' in line else ''
            if key in mime_types:
                continue
        new_lines.append(line)
    
    with open(mimeapps_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

def update_env_lua(filepath):
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = re.sub(
            r'hl\.env\("BROWSER",\s*"[^"]*"\)',
            f'hl.env("BROWSER", "{target_binary}")',
            content
        )
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)

update_env_lua(os.path.expanduser('~/.config/hypr/modules/env.lua'))
update_env_lua(os.path.expanduser('~/dots/hypr/modules/env.lua'))

subprocess.run([
    'notify-send',
    '-i', 'web-browser',
    'Default Browser Updated',
    f'Default browser set to {target_name} ({target_desktop})'
], capture_output=True)
