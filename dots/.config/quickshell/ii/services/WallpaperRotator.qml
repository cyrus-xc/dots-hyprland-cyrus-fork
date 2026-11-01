import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

/**
 * Periodically switches the wallpaper to another image from a folder.
 * Configured in Config.options.background.autoRotate.
 */
Singleton {
    id: root

    readonly property var options: Config.options.background.autoRotate
    readonly property bool enabled: Config.ready && options.enable
    readonly property string folder: FileUtils.trimFileProtocol(
        options.folder.length > 0 ? options.folder : `${Directories.pictures}/Wallpapers`)
    readonly property list<string> extensions: Wallpapers.extensions

    function load() {} // For forcing initialization

    function next() {
        listProc.running = false
        listProc.running = true
    }

    function pickNext(files) {
        const current = Config.options.background.wallpaperPath
        const candidates = files.filter(f => f !== current)
        if (candidates.length === 0) return ""
        if (root.options.shuffle) {
            return candidates[Math.floor(Math.random() * candidates.length)]
        }
        // Sequential: the first file sorting after the current one, wrapping around
        return files.find(f => f > current) ?? files[0]
    }

    Timer {
        id: rotateTimer
        running: root.enabled
        repeat: true
        interval: Math.max(1, root.options.intervalMinutes) * 60 * 1000
        onTriggered: root.next()
    }

    Process {
        id: listProc
        command: [
            "find", root.folder, "-maxdepth", "1", "-type", "f",
            "-regextype", "posix-extended", "-iregex", `.*\\.(${root.extensions.join("|")})`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = text.split("\n").filter(f => f.length > 0).sort()
                const path = root.pickNext(files)
                if (path.length > 0) Wallpapers.apply(path)
            }
        }
    }

    IpcHandler {
        target: "wallpaperRotator"

        function next(): void {
            root.next()
        }
    }
}
