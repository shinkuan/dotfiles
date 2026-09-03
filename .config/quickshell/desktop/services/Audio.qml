pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Quickshell loses the default node when the default changes while the
    // old one disappears (e.g. a streaming sink going away); fall back to
    // the name WirePlumber publishes in its metadata
    property string defaultSinkName: ""
    property string defaultSourceName: ""
    readonly property PwNode sink: Pipewire.defaultAudioSink ?? sinks.find(n => n.name === defaultSinkName) ?? null
    readonly property PwNode source: Pipewire.defaultAudioSource ?? sources.find(n => n.name === defaultSourceName) ?? null
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && (n.type & PwNodeType.Audio))
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && (n.type & PwNodeType.Audio))
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? true
    // a stream is audible only while its link to a sink is active
    readonly property bool playing: Pipewire.links.values.some(l => l.state === PwLinkState.Active && (l.source?.isStream ?? false) && (l.target?.isSink ?? false))

    PwObjectTracker {
        objects: [...root.sinks, ...root.sources, ...root.streams, ...Pipewire.links.values]
    }

    function metadataName(text: string): string {
        const m = text.match(/"name"\s*:\s*"([^"]+)"/);
        return m ? m[1] : "";
    }

    Process {
        id: metaSink

        command: ["pw-metadata", "0", "default.audio.sink"]
        stdout: StdioCollector {
            onStreamFinished: root.defaultSinkName = root.metadataName(text)
        }
    }

    Process {
        id: metaSource

        command: ["pw-metadata", "0", "default.audio.source"]
        stdout: StdioCollector {
            onStreamFinished: root.defaultSourceName = root.metadataName(text)
        }
    }

    Timer {
        id: refreshDefaults

        interval: 300
        running: true
        onTriggered: {
            metaSink.running = true;
            metaSource.running = true;
        }
    }

    onSinksChanged: refreshDefaults.restart()
    onSourcesChanged: refreshDefaults.restart()

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged(): void {
            refreshDefaults.restart();
        }

        function onDefaultAudioSourceChanged(): void {
            refreshDefaults.restart();
        }
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

        function get(): string {
            return `${root.displayName(root.sink) || "(no sink)"} ${Math.round(root.volume * 100)}% ${root.muted ? "muted" : ""} | sinks: ${root.sinks.map(n => root.displayName(n)).join(", ")}`;
        }
    }
}
