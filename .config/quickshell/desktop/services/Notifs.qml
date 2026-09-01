pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../config"

// Notification daemon: live popups plus a history that survives restarts.
// Entries are plain objects; `notif` holds the live Notification while it
// is still open (actions / inline reply only work on those).
Singleton {
    id: root

    property list<var> list: []      // newest first
    property list<var> popups: []    // ids shown as popups, newest first
    readonly property int unread: list.filter(e => !e.read).length
    readonly property bool dnd: ShellState.dnd
    readonly property string dir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/desktop-shell`
    property bool loaded: false

    function timeout(entry): int {
        if (entry.urgency === NotificationUrgency.Critical)
            return Config.notifications.criticalTimeout;
        if (entry.expireTimeout > 0)
            return entry.expireTimeout;
        return Config.notifications.timeout;
    }

    function find(id: int): var {
        return list.find(e => e.id === id) ?? null;
    }

    function update(id: int, patch): void {
        list = list.map(e => e.id === id ? Object.assign({}, e, patch) : e);
        save.restart();
    }

    function iconSource(entry): string {
        const icon = entry.appIcon ?? "";
        if (icon === "")
            return entry.desktopEntry ? Quickshell.iconPath(entry.desktopEntry, true) || "" : "";
        if (icon.startsWith("/") || icon.startsWith("file://"))
            return icon;
        return Quickshell.iconPath(icon, true) || "";
    }

    function add(n: Notification): void {
        n.tracked = true;
        const entry = {
            id: n.id,
            appName: n.appName,
            appIcon: n.appIcon,
            desktopEntry: n.desktopEntry,
            summary: n.summary,
            body: n.body,
            image: n.image,
            urgency: n.urgency,
            expireTimeout: n.expireTimeout,
            time: Date.now(),
            actions: n.actions.map(a => ({ id: a.identifier, text: a.text })),
            hasInlineReply: n.hasInlineReply,
            replyPlaceholder: n.inlineReplyPlaceholder,
            transient: n.transient,
            read: false,
            notif: n
        };
        // a replaced notification keeps its slot
        const existing = list.findIndex(e => e.id === n.id);
        list = existing >= 0 ? list.map((e, i) => i === existing ? entry : e) : [entry, ...list].slice(0, Config.notifications.maxHistory);
        n.closed.connect(() => root.onClosed(n.id));
        if (!dnd) {
            popups = [n.id, ...popups.filter(id => id !== n.id)];
            const t = timeout(entry);
            if (t > 0)
                expireComp.createObject(root, { notifId: n.id, interval: t });
        }
        save.restart();
    }

    function onClosed(id: int): void {
        popups = popups.filter(p => p !== id);
        const e = find(id);
        if (e?.transient)
            list = list.filter(x => x.id !== id);
        else
            update(id, { notif: null });
    }

    // hide the popup only; history keeps it
    function hidePopup(id: int): void {
        popups = popups.filter(p => p !== id);
    }

    function dismiss(id: int): void {
        const e = find(id);
        popups = popups.filter(p => p !== id);
        if (e?.notif)
            e.notif.dismiss();
        else
            list = list.filter(x => x.id !== id);
        save.restart();
    }

    function remove(id: int): void {
        const e = find(id);
        if (e?.notif)
            e.notif.dismiss();
        list = list.filter(x => x.id !== id);
        popups = popups.filter(p => p !== id);
        save.restart();
    }

    function clearAll(): void {
        for (const e of list)
            if (e.notif)
                e.notif.dismiss();
        list = [];
        popups = [];
        save.restart();
    }

    function markAllRead(): void {
        if (unread === 0)
            return;
        list = list.map(e => e.read ? e : Object.assign({}, e, { read: true }));
        save.restart();
    }

    function invoke(id: int, actionId: string): void {
        const e = find(id);
        const a = e?.notif?.actions.find(x => x.identifier === actionId);
        if (a)
            a.invoke();
        hidePopup(id);
    }

    function reply(id: int, text: string): void {
        const e = find(id);
        if (e?.notif?.hasInlineReply)
            e.notif.sendInlineReply(text);
        hidePopup(id);
    }

    Component {
        id: expireComp

        Timer {
            property int notifId

            running: true
            onTriggered: {
                root.hidePopup(notifId);
                destroy();
            }
        }
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        onNotification: n => root.add(n)
    }

    Timer {
        id: save

        interval: 800
        onTriggered: {
            if (!root.loaded)
                return;
            const data = root.list.filter(e => !e.transient).map(e => {
                const copy = Object.assign({}, e);
                delete copy.notif;
                return copy;
            });
            file.setText(JSON.stringify(data));
        }
    }

    FileView {
        id: file

        path: root.dir + "/notifications.json"
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (root.list.length === 0)
                    root.list = data.map(e => Object.assign({}, e, { notif: null }));
            } catch (e) {
                console.warn("Notifs: cannot parse notifications.json:", e);
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clearAll();
        }

        function toggleDnd(): void {
            ShellState.toggle("dnd");
        }

        function dnd(): bool {
            return root.dnd;
        }
    }
}
