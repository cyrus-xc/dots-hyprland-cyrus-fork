pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string killDialogQmlPath: FileUtils.trimFileProtocol(Quickshell.shellPath("killDialog.qml"))

    function load() {
        // dummy to force init
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) checkConflictsProc.running = true
        }
    }

    Process {
        id: checkConflictsProc
        // Quickshell can display items from an existing SNI watcher. A running
        // kded6 alone is not a conflict; check whether the tray interface works.
        command: ["bash", "-c", `trays=""; if pidof kded6 >/dev/null && ! busctl --user --auto-start=no get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems >/dev/null 2>&1; then trays="$(pidof kded6)"; fi; printf '%s;%s' "$trays" "$(pidof mako dunst)"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text;
                const conflictingTrays = output.split(";")[0].trim().length > 0;
                const conflictingNotifications = output.split(";")[1].trim().length > 0;
                var openDialog = false;
                if (conflictingTrays) {
                    if (!Config.options.conflictKiller.autoKillTrays) openDialog = true;
                    else Quickshell.execDetached(["busctl", "--user", "--auto-start=no", "call", "org.kde.kded6", "/kded", "org.kde.kded6", "loadModule", "s", "statusnotifierwatcher"])
                }
                if (conflictingNotifications) {
                    if (!Config.options.conflictKiller.autoKillNotificationDaemons) openDialog = true;
                    else Quickshell.execDetached(["killall", "mako", "dunst"])
                }
                if (openDialog) {
                    Quickshell.execDetached(["qs", "-p", root.killDialogQmlPath])
                }
            }
        }
    }
}
