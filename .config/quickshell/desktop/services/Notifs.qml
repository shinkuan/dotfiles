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

    // entries are keyed by `key` (unique across restarts); `id` is only
    // meaningful while `notif` is live, since server ids restart at 1
    property list<var> list: []      // newest first
    property list<var> popups: []    // keys shown as popups, newest first
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

    function find(key: string): var {
        return list.find(e => e.key === key) ?? null;
    }

    function update(key: string, patch): void {
        list = list.map(e => e.key === key ? Object.assign({}, e, patch) : e);
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
        // a replaced notification (same live id) keeps its slot and key
        const existing = list.findIndex(e => e.notif && e.id === n.id);
        const key = existing >= 0 ? list[existing].key : `${Date.now()}-${n.id}`;
        const entry = {
            key,
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
        list = existing >= 0 ? list.map((e, i) => i === existing ? entry : e) : [entry, ...list].slice(0, Config.notifications.maxHistory);
        if (existing < 0)
            n.closed.connect(() => root.onClosed(key));
        if (!dnd) {
            popups = [key, ...popups.filter(k => k !== key)];
            const t = timeout(entry);
            if (t > 0)
                expireComp.createObject(root, { notifKey: key, interval: t });
        }
        save.restart();
    }

    function onClosed(key: string): void {
        popups = popups.filter(p => p !== key);
        const e = find(key);
        if (e?.transient)
            list = list.filter(x => x.key !== key);
        else
            update(key, { notif: null });
    }

    // hide the popup only; history keeps it
    function hidePopup(key: string): void {
        popups = popups.filter(p => p !== key);
    }

    function dismiss(key: string): void {
        const e = find(key);
        popups = popups.filter(p => p !== key);
        if (e?.notif)
            e.notif.dismiss();
        else
            list = list.filter(x => x.key !== key);
        save.restart();
    }

    function remove(key: string): void {
        const e = find(key);
        if (e?.notif)
            e.notif.dismiss();
        list = list.filter(x => x.key !== key);
        popups = popups.filter(p => p !== key);
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

    function invoke(key: string, actionId: string): void {
        const e = find(key);
        const a = e?.notif?.actions.find(x => x.identifier === actionId);
        if (a)
            a.invoke();
        hidePopup(key);
    }

    function reply(key: string, text: string): void {
        const e = find(key);
        if (e?.notif?.hasInlineReply)
            e.notif.sendInlineReply(text);
        hidePopup(key);
    }

    property var hovered: ({})

    function setHovered(key: string, on: bool): void {
        const copy = Object.assign({}, hovered);
        if (on)
            copy[key] = true;
        else
            delete copy[key];
        hovered = copy;
    }

    Component {
        id: expireComp

        Timer {
            property string notifKey

            running: !root.hovered[notifKey]
            onTriggered: {
                root.hidePopup(notifKey);
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
                const data = JSON.parse(text()).filter(e => e.key).map(e => Object.assign({}, e, { notif: null }));
                // live entries that arrived before the file loaded stay on top
                root.list = [...root.list, ...data.filter(e => !root.list.some(x => x.key === e.key))].slice(0, Config.notifications.maxHistory);
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
