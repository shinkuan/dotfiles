pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && (n.type & PwNodeType.Audio))
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && (n.type & PwNodeType.Audio))
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && (n.type & PwNodeType.Audio) && !n.isSink)

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? true
    readonly property bool playing: streams.some(s => s.ready && s.properties?.["state"] !== "suspended")

    PwObjectTracker {
        objects: [...root.sinks, ...root.sources, ...root.streams]
    }

    function displayName(node: PwNode): string {
        if (!node)
            return "";
        return node.nickname || node.description || node.name;
    }

    function iconFor(node: PwNode): string {
        const key = ((node?.name ?? "") + " " + (node?.description ?? "") + " " + (node?.properties?.["device.form-factor"] ?? "")).toLowerCase();
        if (key.includes("bluez") || key.includes("bluetooth"))
            return "bluetooth_audio";
        if (key.includes("headset") || key.includes("headphone"))
            return "headphones";
        if (key.includes("hdmi") || key.includes("displayport"))
            return "tv";
        if (key.includes("mic"))
            return "mic";
        return node?.isSink ? "speaker" : "mic";
    }

    function setVolume(node: PwNode, value: real): void {
        if (!node?.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function increment(delta: real): void {
        setVolume(sink, volume + delta);
    }

    function toggleMute(node: PwNode): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    IpcHandler {
        target: "audio"

        function increment(): void {
            root.increment(0.05);
        }

        function decrement(): void {
            root.increment(-0.05);
        }

        function mute(): void {
            root.toggleMute(root.sink);
        }

        function muteSource(): void {
            root.toggleMute(root.source);
        }

        function setVolume(value: real): void {
            root.setVolume(root.sink, value);
        }
    }
}
