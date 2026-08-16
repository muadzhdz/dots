#!/usr/bin/env python3
import os
import sys
import glob
import re
import urllib.parse
import subprocess
import shutil

apps = {}
desktop_dirs = [
    os.path.expanduser('~/.local/share/applications'),
    '/usr/share/applications',
    '/usr/local/share/applications'
]

for d in desktop_dirs:
    if not os.path.exists(d):
        continue
    for filepath in sorted(glob.glob(os.path.join(d, '*.desktop'))):
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
                if '[Desktop Entry]' not in content:
                    continue
                entry_section = content.split('[Desktop Entry]')[1].split('\n[')[0]
                name_match = re.search(r'^Name=(.+)$', entry_section, re.MULTILINE)
                exec_match = re.search(r'^Exec=(.+)$', entry_section, re.MULTILINE)
                nodisplay = re.search(r'^NoDisplay=true$', entry_section, re.MULTILINE | re.IGNORECASE)
                
                if name_match and exec_match and not nodisplay:
                    name = name_match.group(1).strip()
                    exec_cmd = exec_match.group(1).strip()
                    exec_cmd = re.sub(r'%[a-zA-Z]', '', exec_cmd).strip()
                    if name not in apps:
                        apps[name] = exec_cmd
        except Exception:
            pass

sorted_app_names = sorted(apps.keys(), key=lambda s: s.lower())
input_data = '\n'.join(sorted_app_names)

# Sidebar position: "right" anchors east (slides in from the left edge),
# "left" anchors west (slides in from the right edge), default stays centered.
side = sys.argv[1] if len(sys.argv) > 1 else "center"
theme_str = ""
window_title = ""
if side == "right":
    theme_str = "-theme-str", "window { location: east; anchor: east; }"
    window_title = "-window-title", "SidebarRight"
elif side == "left":
    theme_str = "-theme-str", "window { location: west; anchor: west; }"
    window_title = "-window-title", "SidebarLeft"

rofi_cmd = [
    'rofi', '-dmenu', '-i',
    '-p', ' Apps',
    '-matching', 'fuzzy',
    '-sort'
]
if theme_str:
    rofi_cmd += list(theme_str) + list(window_title)

spawn_env = {k: v for k, v in os.environ.items() if k != 'DISPLAY'}
proc = subprocess.Popen(rofi_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, env=spawn_env)
stdout, _ = proc.communicate(input=input_data)

selection = stdout.strip()
if not selection:
    sys.exit(0)

if selection in apps:
    cmd = apps[selection]
    subprocess.Popen(cmd, shell=True, start_new_session=True)
    sys.exit(0)

def is_url(text):
    if re.match(r'^https?://', text, re.IGNORECASE):
        return True
    if re.match(r'^[a-zA-Z0-9][-a-zA-Z0-9.]*\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$', text):
        return True
    if re.match(r'^localhost(:[0-9]+)?(/.*)?$', text, re.IGNORECASE):
        return True
    if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?(/.*)?$', text):
        return True
    return False

if is_url(selection):
    url = selection if selection.lower().startswith(('http://', 'https://')) else f'https://{selection}'
    subprocess.Popen(['xdg-open', url], start_new_session=True)
elif shutil.which(selection):
    subprocess.Popen([selection], start_new_session=True)
else:
    encoded = urllib.parse.quote(selection)
    search_url = f'https://www.google.com/search?q={encoded}'
    subprocess.Popen(['xdg-open', search_url], start_new_session=True)
