#!/usr/bin/env python3
import sys, os, glob, json, subprocess

mode = sys.argv[1] if len(sys.argv) > 1 else "dark"
is_dark = (mode == "dark")

# 1. Update VSCode / Code - OSS / VSCodium
vscode_theme = "Default Dark Modern" if is_dark else "Default Light Modern"

color_customizations = {
    "editor.background": "#000000" if is_dark else "#ffffff",
    "sideBar.background": "#000000" if is_dark else "#ffffff",
    "sideBar.border": "#222222" if is_dark else "#e0e0e0",
    "activityBar.background": "#000000" if is_dark else "#ffffff",
    "activityBar.border": "#222222" if is_dark else "#e0e0e0",
    "titleBar.activeBackground": "#000000" if is_dark else "#ffffff",
    "titleBar.border": "#222222" if is_dark else "#e0e0e0",
    "statusBar.background": "#000000" if is_dark else "#ffffff",
    "statusBar.border": "#222222" if is_dark else "#e0e0e0",
    "terminal.background": "#000000" if is_dark else "#ffffff",
    "editorGroupHeader.tabsBackground": "#000000" if is_dark else "#ffffff",
    "tab.activeBackground": "#111111" if is_dark else "#f5f5f5",
    "tab.inactiveBackground": "#000000" if is_dark else "#ffffff",
    "tab.border": "#222222" if is_dark else "#e0e0e0",
    "panel.background": "#000000" if is_dark else "#ffffff",
    "panel.border": "#222222" if is_dark else "#e0e0e0"
}

for settings_path in [
    os.path.expanduser('~/.config/Code/User/settings.json'),
    os.path.expanduser('~/.config/Code - OSS/User/settings.json'),
    os.path.expanduser('~/.config/VSCodium/User/settings.json')
]:
    parent_dir = os.path.dirname(settings_path)
    if os.path.exists(parent_dir):
        try:
            data = {}
            if os.path.exists(settings_path):
                with open(settings_path, 'r') as f:
                    data = json.load(f)
            data['window.autoDetectColorScheme'] = True
            data['workbench.preferredDarkColorTheme'] = 'Default Dark Modern'
            data['workbench.preferredLightColorTheme'] = 'Default Light Modern'
            data['workbench.colorTheme'] = vscode_theme
            data['workbench.colorCustomizations'] = color_customizations
            with open(settings_path, 'w') as f:
                json.dump(data, f, indent=4)
        except Exception:
            pass

# 2. Update OBS Studio Theme
obs_theme = "com.rice.MonochromeDark" if is_dark else "com.rice.MonochromeLight"
obs_user_ini = os.path.expanduser('~/.config/obs-studio/user.ini')
if os.path.exists(obs_user_ini):
    try:
        with open(obs_user_ini, 'r') as f:
            lines = f.readlines()
        new_lines = []
        in_appearance = False
        theme_set = False
        for line in lines:
            if line.strip().startswith('[Appearance]'):
                in_appearance = True
                new_lines.append(line)
                continue
            elif line.strip().startswith('[') and in_appearance:
                if not theme_set:
                    new_lines.append(f'Theme={obs_theme}\n')
                    theme_set = True
                in_appearance = False
            
            if in_appearance and line.strip().startswith('Theme='):
                new_lines.append(f'Theme={obs_theme}\n')
                theme_set = True
            else:
                new_lines.append(line)
        if not theme_set:
            if '[Appearance]' not in ''.join(lines):
                new_lines.append(f'\n[Appearance]\nTheme={obs_theme}\n')
        with open(obs_user_ini, 'w') as f:
            f.writelines(new_lines)
    except Exception:
        pass

# 3. Update Qt6ct config (For Polkit KDE and Hyprland Share Picker)
qt_palette = "monochrome_dark.conf" if is_dark else "monochrome_light.conf"
qt_qss = "monochrome_dark.qss" if is_dark else "monochrome_light.qss"
qt6ct_path = os.path.expanduser('~/.config/qt6ct/qt6ct.conf')
if os.path.exists(qt6ct_path):
    try:
        with open(qt6ct_path, 'r') as f:
            content = f.read()
        import re
        content = re.sub(r'color_scheme_path=.*', f'color_scheme_path={os.path.expanduser("~/.config/qt6ct/colors/")}{qt_palette}', content)
        content = re.sub(r'qss_paths=.*', f'qss_paths={os.path.expanduser("~/.config/qt6ct/qss/")}{qt_qss}', content)
        with open(qt6ct_path, 'w') as f:
            f.write(content)
    except Exception:
        pass

# 4. Broadcast SyncTheme to running Neovim instances
runtime_dir = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
socks = glob.glob(f'{runtime_dir}/nvim*') + glob.glob('/tmp/nvim*') + glob.glob('/tmp/nvim*/*')
for sock in socks:
    if os.path.exists(sock) and not os.path.isdir(sock):
        try:
            cmd = "<Esc>:SyncTheme<CR>"
            subprocess.run(['nvim', '--server', sock, '--remote-send', cmd],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1)
        except Exception:
            pass

print(f"Apps sync completed for mode: {mode}")
