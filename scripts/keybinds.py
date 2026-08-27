#!/usr/bin/env python3
import os
import re

HOME = os.path.expanduser("~")
SRC_PATH = os.path.join(HOME, ".config/hypr/modules/binds.lua")

SCRIPTS_DIR = "$HOME/.config/scripts"

EXEC_LABELS = {
    "terminal": "Open Terminal",
    "fileManager": "Open File Manager",
    "launcher": "App Launcher",
    "powerMenu": "Power Menu",
    "emojiPicker": "Emoji Picker",
    "screenshot": "Screenshot",
    "ocr": "OCR Screenshot",
    "clipRofi": "Clipboard History",
    "monitorScaling": "Cycle Display Scale",
    "displayMenu": "Display Settings",
    "wallpaper": "Random Wallpaper",
    "wallpaperPicker": "Wallpaper Picker",
    "themeMode": "Theme Mode Switcher",
    "lock": "Lock Screen",
}


def describe_exec(cmd):
    low = cmd.lower()
    table = [
        ("theme-mode", "Theme Mode Switcher"),
        ("power-menu", "Power Menu"),
        ("--output-volume raise", "Volume Up"),
        ("--output-volume lower", "Volume Down"),
        ("--output-volume mute-toggle", "Mute"),
        ("wpctl set-mute", "Toggle Mic Mute"),
        ("--brightness raise", "Brightness Up"),
        ("--brightness lower", "Brightness Down"),
        ("playerctl next", "Next Track"),
        ("playerctl play-pause", "Play / Pause"),
        ("playerctl previous", "Previous Track"),
        ("hyprshutdown", "Exit Session"),
        ("wallpaper", "Wallpaper Picker"),
    ]
    for needle, label in table:
        if needle in low:
            return label
    if cmd and len(cmd) < 40:
        return cmd.replace("$HOME", "~")
    return ""


DISP_LABELS = {
    "window.close": "Close Window",
    "window.fullscreen": "Toggle Fullscreen",
    "window.float": "Toggle Floating",
    "window.pseudo": "Toggle Pseudo-Tile",
    "window.swap": "Swap Window",
    "window.drag": "Move Window (Drag)",
    "window.resize": "Resize Window (Drag)",
    "window.cycle_next": "Cycle Windows",
    "window.bring_to_top": "Bring Window to Top",
    "window.move": "Move Window",
    "workspace.toggle_special": "Toggle Scratchpad",
    "focus": "Focus",
    "layout": "Toggle Split Layout",
}


def resolve_var(expr, var_map):
    expr = expr.strip()
    m = re.match(r"^(\w+)\s*\.\.\s*\"([^\"]*)\"$", expr)
    if m and m.group(1) in var_map:
        return var_map[m.group(1)] + m.group(2)
    if expr in var_map:
        return var_map[expr]
    return expr


def refine(disp, body, label):
    if disp == "focus":
        m = re.search(r"direction\s*=\s*\"(\w+)\"", body)
        if m:
            return "Focus %s" % m.group(1).capitalize()
        m = re.search(r"monitor\s*=\s*\"([+-]?\d+)\"", body)
        if m:
            return "Focus Next Monitor" if m.group(1).startswith("+") else "Focus Previous Monitor"
        m = re.search(r"workspace\s*=\s*\"([^\"]*)\"", body)
        if m:
            return "Next Workspace" if m.group(1) == "e+1" else "Previous Workspace"
    if disp == "window.swap":
        m = re.search(r"direction\s*=\s*\"(\w)\"", body)
        if m:
            names = {"l": "Left", "r": "Right", "u": "Up", "d": "Down"}
            return "Swap Window %s" % names.get(m.group(1), m.group(1))
    if disp == "window.cycle_next":
        if "prev" in body:
            return "Focus Previous Window"
        return "Focus Next Window"
    if disp == "window.fullscreen":
        if "maximized" in body:
            return "Maximize Window"
    if disp == "window.move":
        if "special:magic" in body:
            return "Move to Scratchpad"
    return label


def parse_bind(body, var_map):
    if "mainMod" in body:
        m = re.search(r"\"([^\"]*)\"", body)
        combo = ("SUPER" + m.group(1)) if m else ""
    else:
        m = re.search(r"\"([^\"]*)\"", body)
        combo = m.group(1) if m else ""
    if not combo:
        return None

    dm = re.search(r"description\s*=\s*\"([^\"]*)\"", body)
    desc = dm.group(1) if dm else ""

    mm = re.search(r"hl\.dsp\.([a-zA-Z_.]+)\s*\(", body)
    if not mm:
        return (combo, desc or combo, "")

    disp = mm.group(1)
    cmd = ""
    label = ""

    if disp == "exec_cmd":
        am = re.search(r"exec_cmd\(([^)]*)\)", body)
        arg = am.group(1).strip() if am else ""
        if arg and not arg.startswith('"'):
            if '"' in arg:
                cmd = resolve_var(arg, var_map) if re.match(r"^[\w.\/]+\s*\.\.\s*\"[^\"]*\"$", arg) else ""
            else:
                cmd = resolve_var(arg, var_map)
            label = EXEC_LABELS.get(arg.split(" ")[0], describe_exec(cmd))
        elif arg.startswith('"'):
            m = re.search(r'exec_cmd\("((?:[^"\\]|\\.)*)"', body)
            if m:
                raw = m.group(1).replace('\\"', '"')
                if ".." in body[am.start():]:
                    cmd = ""
                else:
                    cmd = raw
                label = describe_exec(raw)
        label = desc or label
        if "--reverse" in body:
            label = "Reverse Cycle Scale"
    else:
        label = DISP_LABELS.get(disp, desc or disp.replace(".", " ").title())
        label = refine(disp, body, label)

    combo = re.sub(r"\b[a-z]+\b", lambda x: x.group(0).upper(), combo)
    return (combo, label or combo, cmd)


def main():
    with open(SRC_PATH) as f:
        src = f.read()

    var_map = {"scriptsDir": SCRIPTS_DIR}
    for name, val in re.findall(r"local\s+(\w+)\s*=\s*(.+)", src):
        val = val.strip()
        if name == "scriptsDir":
            continue
        lits = re.findall(r'"([^"]*)"', val)
        if "scriptsDir" in val and lits:
            var_map[name] = SCRIPTS_DIR + lits[-1]
        elif 'os.getenv("HOME")' in val and lits:
            var_map[name] = "$HOME" + lits[-1]
        elif lits:
            var_map[name] = lits[0]
        else:
            var_map[name] = val

    rows = []

    loop = re.compile(r"for\s+i\s*=\s*1,\s*10\s+do(.*?)end", re.S)
    for m in loop.finditer(src):
        for i in range(1, 11):
            key = str(i % 10)
            rows.append(("SUPER + " + key, "Focus Workspace %d" % i, ""))
            rows.append(("SUPER + SHIFT + " + key, "Move to Workspace %d" % i, ""))
    src = loop.sub("", src)

    def find_binds(text):
        binds = []
        n = len(text)
        i = 0
        while True:
            j = text.find("hl.bind(", i)
            if j < 0:
                break
            k = text.find("(", j)
            depth = 0
            pos = k
            while pos < n:
                c = text[pos]
                if c == "(":
                    depth += 1
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        break
                pos += 1
            binds.append(text[k + 1:pos])
            i = pos + 1
        return binds

    for body in find_binds(src):
        try:
            row = parse_bind(body, var_map)
        except Exception:
            row = None
        if row:
            rows.append(row)

    for combo, label, cmd in rows:
        print("%s\t%s\t%s" % (combo, label, cmd))


if __name__ == "__main__":
    main()
