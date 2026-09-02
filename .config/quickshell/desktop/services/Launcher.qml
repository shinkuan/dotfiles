pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Launcher model: apps, actions (from config.json), qalc, cliphist and the
// scheme / variant / wallpaper pickers. Views only render `results`.
Singleton {
    id: root

    property bool open: false
    property string query: ""
    property int selected: 0
    property string mode: "apps"
    property string term: ""
    property list<var> results: []
    property string calcResult: ""
    property list<var> clips: []
    property list<var> wallpapers: []
    property list<var> schemes: []
    property list<var> emojis: []   // [{ char, name }]
    property bool hasApp2unit: false
    readonly property list<string> variants: ["tonalspot", "vibrant", "expressive", "fidelity", "fruitsalad", "monochrome", "neutral", "rainbow", "content"]
    readonly property string cacheDir: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/desktop-shell/clip`
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/Pictures/Wallpapers`
    readonly property list<var> actions: Config.launcher.actions.filter(a => a.enabled !== false && (!a.dangerous || Config.launcher.showDangerous))
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/desktop-shell`
    property var usage: ({})

    function show(): void {
        query = "";
        selected = 0;
        open = true;
        clipList.running = true;
        wallList.running = true;
        schemeList.running = true;
        compute();
    }

    function hide(): void {
        open = false;
    }

    function toggle(): void {
        if (open)
            hide();
        else
            show();
    }

    onQueryChanged: {
        selected = 0;
        compute();
    }

    function score(q: string, text: string): real {
        if (!text)
            return 0;
        const t = text.toLowerCase();
        if (q === "")
            return 1;
        if (t === q)
            return 200;
        if (t.startsWith(q))
            return 150 - t.length * 0.01;
        const words = t.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q)))
            return 120 - t.length * 0.01;
        const idx = t.indexOf(q);
        if (idx >= 0)
            return 90 - idx * 0.5;
        if (!Config.launcher.fuzzy)
            return 0;
        let ti = 0, gaps = 0, last = -1;
        for (const ch of q) {
            const i = t.indexOf(ch, ti);
            if (i < 0)
                return 0;
            if (last >= 0)
                gaps += i - last - 1;
            last = i;
            ti = i + 1;
        }
        return Math.max(1, 50 - gaps);
    }

    function mathLike(q: string): bool {
        return /^[\d\s()+\-*/^.,%!]+$/.test(q) && /[\d]/.test(q) && /[+\-*/^%!]/.test(q) || /^(sqrt|sin|cos|tan|log|ln|abs|round|floor|ceil|pi|e)\b/.test(q);
    }

    function compute(): void {
        const q = query;
        const p = Config.launcher;
        if (q.startsWith(p.actionPrefix)) {
            const rest = q.slice(p.actionPrefix.length);
            const sub = rest.match(/^(scheme|variant|wallpaper)\s*(.*)$/);
            if (sub) {
                mode = sub[1];
                term = sub[2].trim().toLowerCase();
            } else {
                mode = "actions";
                term = rest.trim().toLowerCase();
            }
        } else if (q.startsWith(p.calcPrefix)) {
            mode = "calc";
            term = q.slice(p.calcPrefix.length).trim();
        } else if (q.startsWith(p.clipPrefix)) {
            mode = "clip";
            term = q.slice(p.clipPrefix.length).trim().toLowerCase();
        } else if (p.emojiPrefix !== "" && q.startsWith(p.emojiPrefix) && emojis.length > 0) {
            mode = "emoji";
            term = q.slice(p.emojiPrefix.length).trim().toLowerCase();
        } else {
            mode = "apps";
            term = q.trim().toLowerCase();
        }

        let out = [];
        switch (mode) {
        case "apps":
            if (mathLike(term)) {
                calc.expr = term;
                calc.restart();
                out.push(calcRow(term));
            }
            out = out.concat(appRows(term));
            if (term !== "")
                out = out.concat(actionRows(term).slice(0, 3));
            break;
        case "actions":
            out = actionRows(term);
            break;
        case "calc":
            calc.expr = term;
            calc.restart();
            out = term ? [calcRow(term)] : [];
            break;
        case "clip":
            out = clipRows(term);
            break;
        case "scheme":
            out = schemeRows(term);
            break;
        case "variant":
            out = variantRows(term);
            break;
        case "wallpaper":
            out = wallpaperRows(term);
            break;
        case "emoji":
            out = emojiRows(term);
            break;
        }
        results = out;
        if (selected >= out.length)
            selected = Math.max(0, out.length - 1);
    }

    function ranked(items, key): list<var> {
        return items.map(i => ({ item: i, s: key(i) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s).map(x => x.item);
    }

    function appRows(q: string): list<var> {
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        const used = a => Math.min(usage[a.id] ?? 0, 20);
        const list = q === "" ? apps.slice().sort((a, b) => (used(b) - used(a)) || a.name.localeCompare(b.name)) : ranked(apps, a => {
            const s = Math.max(score(q, a.name), score(q, a.genericName) * 0.8, score(q, a.comment) * 0.5, ...a.keywords.map(k => score(q, k) * 0.7));
            return s > 0 ? s + used(a) * 2 : 0;
        });
        return list.map(a => ({
            kind: "app",
            title: a.name,
            subtitle: a.genericName || a.comment,
            iconSource: Quickshell.iconPath(a.icon, "application-x-executable"),
            hint: "",
            run: () => root.launchApp(a)
        }));
    }

    function launchApp(entry): void {
        const copy = Object.assign({}, usage);
        copy[entry.id] = (copy[entry.id] ?? 0) + 1;
        usage = copy;
        usageFile.setText(JSON.stringify(usage));
        if (hasApp2unit)
            Quickshell.execDetached(["app2unit", "--", entry.id.endsWith(".desktop") ? entry.id : entry.id + ".desktop"]);
        else
            entry.execute();
    }

    function actionRows(q: string): list<var> {
        const list = q === "" ? actions : ranked(actions, a => Math.max(score(q, a.name), score(q, a.description) * 0.6));
        return list.map(a => ({
            kind: "action",
            title: a.name,
            subtitle: a.description ?? "",
            icon: a.icon ?? "bolt",
            danger: a.dangerous === true,
            hint: a.command?.[0]?.startsWith("@") ? "›" : "",
            run: () => root.runAction(a)
        }));
    }

    function runAction(a): void {
        const cmd = a.command ?? [];
        if (cmd[0] === "@scheme" || cmd[0] === "@variant" || cmd[0] === "@wallpaper") {
            query = Config.launcher.actionPrefix + cmd[0].slice(1) + " ";
            return;
        }
        if (cmd[0] === "@config") {
            Quickshell.execDetached(["xdg-open", Quickshell.shellDir + "/config.json"]);
        } else if (cmd.length > 0) {
            Quickshell.execDetached(cmd);
        }
        hide();
    }

    function calcRow(expr: string): var {
        return {
            kind: "calc",
            title: calcResult || "…",
            subtitle: expr,
            icon: "calculate",
            hint: "copy",
            run: () => {
                if (calcResult)
                    Quickshell.execDetached(["wl-copy", "--", calcResult]);
                hide();
            }
        };
    }

    function clipRows(q: string): list<var> {
        const list = q === "" ? clips : ranked(clips, c => score(q, c.preview));
        return list.map(c => ({
            kind: "clip",
            title: c.preview,
            subtitle: c.image ? "Image" : "",
            icon: c.image ? "image" : "content_paste",
            clipId: c.id,
            clipLine: c.line,
            image: c.image,
            hint: "",
            run: () => {
                Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "_", c.id]);
                hide();
            }
        }));
    }

    function deleteClip(line: string): void {
        Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", line]);
        clips = clips.filter(c => c.line !== line);
        compute();
    }

    function schemeRows(q: string): list<var> {
        const flat = [];
        for (const s of schemes)
            for (const f of s.flavours)
                flat.push({ name: s.name, flavour: f });
        const list = q === "" ? flat : ranked(flat, x => Math.max(score(q, x.name), score(q, x.flavour) * 0.8, score(q, x.name + " " + x.flavour)));
        return list.map(x => ({
            kind: "scheme",
            title: x.name,
            subtitle: x.flavour,
            icon: "palette",
            hint: "",
            run: () => {
                Quickshell.execDetached(["scheme", "set", "--name", x.name, "--flavour", x.flavour]);
                hide();
            }
        }));
    }

    function variantRows(q: string): list<var> {
        const list = q === "" ? variants : ranked(variants, v => score(q, v));
        return list.map(v => ({
            kind: "variant",
            title: v,
            subtitle: "Scheme variant",
            icon: "colors",
            hint: "",
            run: () => {
                Quickshell.execDetached(["scheme", "set", "--variant", v]);
                hide();
            }
        }));
    }

    function wallpaperRows(q: string): list<var> {
        const list = q === "" ? wallpapers : ranked(wallpapers, w => score(q, w.name));
        return list.map(w => ({
            kind: "wallpaper",
            title: w.name,
            subtitle: "",
            thumb: w.path,
            hint: "",
            run: () => {
                Quickshell.execDetached(["wallpaper", "-f", w.path]);
                hide();
            }
        }));
    }

    function emojiRows(q: string): list<var> {
        const list = q === "" ? emojis.slice(0, 60) : ranked(emojis, e => score(q, e.name)).slice(0, 60);
        return list.map(e => ({
            kind: "emoji",
            title: e.name,
            subtitle: "",
            emoji: e.char,
            hint: "copy + type",
            run: () => {
                Quickshell.execDetached(["wl-copy", "--", e.char]);
                hide();
                typeLater.text = e.char;
                typeLater.restart();
            }
        }));
    }

    // typed after the overlay has released keyboard focus
    Timer {
        id: typeLater

        property string text: ""

        interval: 200
        onTriggered: Quickshell.execDetached(["wtype", "--", text])
    }

    FileView {
        path: Config.launcher.emojiFile
        printErrors: false
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                const m = line.match(/^[0-9A-F ]+;\s*fully-qualified\s*#\s*(\S+)\s+E[\d.]+\s+(.*)$/);
                if (m)
                    out.push({ char: m[1], name: m[2] });
            }
            root.emojis = out;
        }
    }

    function activate(index: int): void {
        const r = results[index];
        if (r)
            r.run();
    }

    function move(delta: int): void {
        if (results.length === 0)
            return;
        selected = (selected + delta + results.length) % results.length;
    }

    Timer {
        id: calc

        property string expr: ""

        interval: 120
        onTriggered: {
            if (expr === "") {
                root.calcResult = "";
                return;
            }
            if (qalc.running)
                qalc.running = false;
            qalc.expr = expr;
            qalc.command = ["qalc", "-t", expr];
            qalc.running = true;
        }
    }

    Process {
        id: qalc

        property string expr: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (qalc.expr !== calc.expr)
                    return;
                root.calcResult = text.trim();
                root.compute();
            }
        }
    }

    Process {
        id: clipList

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const preview = line.slice(tab + 1);
                    const img = preview.match(/^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) (\d+x\d+) \]\]$/);
                    out.push({ id: line.slice(0, tab), line, preview: img ? `${img[1].toUpperCase()} ${img[2]}` : preview, image: img !== null });
                }
                root.clips = out;
                if (root.mode === "clip")
                    root.compute();
            }
        }
    }

    Process {
        id: wallList

        command: ["sh", "-c", `find "${root.wallpaperDir}" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.split("\n").filter(l => l).map(p => ({ path: p, name: p.slice(p.lastIndexOf("/") + 1) }));
                if (root.mode === "wallpaper")
                    root.compute();
            }
        }
    }

    Process {
        id: schemeList

        command: ["scheme", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const m = line.match(/^(\S+): flavours \[([^\]]*)\]/);
                    if (m)
                        out.push({ name: m[1], flavours: m[2].split(",").map(s => s.trim()).filter(s => s) });
                }
                root.schemes = out;
                if (root.mode === "scheme")
                    root.compute();
            }
        }
    }

    FileView {
        id: usageFile

        path: root.stateDir + "/launcher-usage.json"
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }

    // entries arrive asynchronously after startup
    Connections {
        target: DesktopEntries.applications

        function onValuesChanged(): void {
            if (root.open)
                root.compute();
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v app2unit"]
        onExited: code => root.hasApp2unit = code === 0
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", cacheDir, stateDir])

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }

        // "show" would collide with the `qs ipc show` subcommand
        function open(): void {
            root.show();
        }

        function close(): void {
            root.hide();
        }

        function search(query: string): void {
            root.show();
            root.query = query;
        }

        function clipboard(): void {
            root.show();
            root.query = Config.launcher.clipPrefix;
        }
    }
}
