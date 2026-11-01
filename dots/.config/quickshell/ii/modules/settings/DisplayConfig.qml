import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true
    baseWidth: Math.max(320, Math.min(640, width - 48))
    property string selectedName: ""
    property bool showHelp: false
    property var selectedMonitor: monitors.find(m => m.name === selectedName) || monitors[0] || null
    property var monitors: []
    property int readErrorCode: 0
    property string readError: readErrorCode === 1
        ? Translation.tr("Unable to read displays. Make sure you are running Hyprland.")
        : readErrorCode === 2 ? Translation.tr("Unable to read displays. Click Refresh to try again.") : ""
    property var activeMonitors: monitors.filter(m => !m.disabled)
    property real leftEdge: Math.min(0, ...activeMonitors.map(m => m.x))
    property real topEdge: Math.min(0, ...activeMonitors.map(m => m.y))
    function logicalWidth(m) { return (m.transform % 2 ? m.height : m.width) / m.scale; }
    function logicalHeight(m) { return (m.transform % 2 ? m.width : m.height) / m.scale; }
    property real layoutWidth: Math.max(1, ...activeMonitors.map(m => m.x + logicalWidth(m))) - leftEdge
    property real layoutHeight: Math.max(1, ...activeMonitors.map(m => m.y + logicalHeight(m))) - topEdge
    function refresh() { if (!query.running) query.running = true; }
    function ratio(m) {
        let a = m.width, b = m.height;
        while (b) { let t = b; b = a % b; a = t; }
        return a ? `${m.width / a}:${m.height / a}` : "—";
    }

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) throw new Error("Invalid monitor data");
                    if (JSON.stringify(root.monitors) !== JSON.stringify(data)) root.monitors = data;
                    root.readErrorCode = 0;
                } catch (e) { root.readErrorCode = 1; }
            }
        }
        onExited: (code, status) => { if (code !== 0) root.readErrorCode = 2; }
    }
    Timer { interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    component Metric: ColumnLayout {
        required property string caption
        required property string value
        spacing: 5
        Layout.fillWidth: true
        StyledText {
            text: caption
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }
        StyledText {
            Layout.fillWidth: true
            text: value
            font.pixelSize: Appearance.font.pixelSize.normal
            elide: Text.ElideRight
        }
    }

    ContentSection {
        title: Translation.tr("Displays")
        icon: "desktop_windows"
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colSubtext
                text: Translation.tr("%1 connected · Select a display to view its settings.").arg(root.monitors.length)
            }
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh")
                enabled: !query.running
                onClicked: root.refresh()
            }
        }

        Rectangle {
            id: canvas
            Layout.fillWidth: true
            implicitHeight: 206
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer2
            clip: true
            property real factor: Math.min((width - 100) / root.layoutWidth, 128 / root.layoutHeight)
            Canvas {
                anchors.fill: parent
                opacity: 0.28
                property color dotColor: Appearance.colors.colOutlineVariant
                onDotColorChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset(); ctx.fillStyle = dotColor;
                    for (let x = 16; x < width; x += 20)
                        for (let y = 16; y < height; y += 20) {
                            ctx.beginPath(); ctx.arc(x, y, 0.8, 0, Math.PI * 2); ctx.fill();
                        }
                }
            }
            Repeater {
                model: root.activeMonitors
                RippleButton {
                    id: monitorButton
                    required property var modelData
                    required property int index
                    property bool selected: root.selectedMonitor?.name === modelData.name
                    x: (canvas.width - root.layoutWidth * canvas.factor) / 2 + (modelData.x - root.leftEdge) * canvas.factor
                    y: 22 + (128 - root.layoutHeight * canvas.factor) / 2 + (modelData.y - root.topEdge) * canvas.factor
                    width: Math.max(1, root.logicalWidth(modelData) * canvas.factor)
                    height: Math.max(1, root.logicalHeight(modelData) * canvas.factor)
                    buttonRadius: Appearance.rounding.normal
                    colBackground: selected ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    onClicked: root.selectedName = modelData.name
                    contentItem: Item {
                        clip: true
                        StyledText {
                            anchors.centerIn: parent
                            text: index + 1
                            font.pixelSize: 38
                            font.weight: Font.Medium
                            color: monitorButton.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer3
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.buttonRadius
                        color: "transparent"
                        border.width: parent.selected ? 2 : 1
                        border.color: parent.selected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    }
                    StyledText {
                        anchors.top: parent.bottom
                        anchors.topMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(110, parent.width)
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: modelData.name
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
            StyledText {
                anchors.centerIn: parent
                visible: root.activeMonitors.length === 0
                text: root.readError || Translation.tr("Reading displays...")
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: root.monitors.length > 1 || root.monitors.some(m => m.disabled)
            Repeater {
                model: root.monitors
                RippleButtonWithIcon {
                    required property var modelData
                    materialIcon: modelData.disabled ? "desktop_access_disabled" : "monitor"
                    mainText: modelData.name
                    colBackground: root.selectedMonitor?.name === modelData.name ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2
                    onClicked: root.selectedName = modelData.name
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: detailColumn.implicitHeight + 36
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer2
            visible: root.selectedMonitor !== null
            ColumnLayout {
                id: detailColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                spacing: 18
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        implicitWidth: 44; implicitHeight: 44
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colPrimaryContainer
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "monitor"
                            iconSize: 24
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        StyledText {
                            Layout.fillWidth: true
                            text: root.selectedMonitor?.model || Translation.tr("Display")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.selectedMonitor?.name || ""
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }
                    StyledText {
                        text: root.selectedMonitor?.disabled ? Translation.tr("Disabled") : Translation.tr("Connected")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colOutlineVariant; opacity: 0.4 }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 20
                    rowSpacing: 20
                    Metric {
                        caption: Translation.tr("Resolution")
                        value: root.selectedMonitor ? `${root.selectedMonitor.width} × ${root.selectedMonitor.height}` : "—"
                    }
                    Metric {
                        caption: Translation.tr("Refresh rate")
                        value: root.selectedMonitor ? Translation.tr("%1 Hz").arg(Number(root.selectedMonitor.refreshRate).toFixed(2)) : "—"
                    }
                    Metric {
                        caption: Translation.tr("Scale")
                        value: root.selectedMonitor ? Translation.tr("%1%").arg(Math.round(root.selectedMonitor.scale * 100)) : "—"
                    }
                    Metric {
                        caption: Translation.tr("Aspect ratio")
                        value: root.selectedMonitor ? root.ratio(root.selectedMonitor) : "—"
                    }
                    Metric {
                        caption: Translation.tr("Desktop space")
                        value: root.selectedMonitor ? `${Math.round(root.logicalWidth(root.selectedMonitor))} × ${Math.round(root.logicalHeight(root.selectedMonitor))}` : "—"
                    }
                    Metric {
                        caption: Translation.tr("Position")
                        value: root.selectedMonitor ? `${root.selectedMonitor.x}, ${root.selectedMonitor.y}` : "—"
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.readError || Translation.tr("Changes are kept only after confirmation.")
            }
            RippleButtonWithIcon {
                materialIcon: "tune"
                mainText: Translation.tr("Configure displays")
                implicitHeight: 42
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                contentItem: RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "tune"
                        iconSize: 20
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                    StyledText {
                        text: Translation.tr("Configure displays")
                        color: Appearance.colors.colOnPrimaryContainer
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
                onClicked: Quickshell.execDetached(["nwg-displays"])
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        RippleButtonWithIcon {
            Layout.fillWidth: true
            materialIcon: root.showHelp ? "expand_less" : "help_outline"
            mainText: Translation.tr("How to adjust displays")
            onClicked: root.showHelp = !root.showHelp
        }
        StyledText {
            visible: root.showHelp
            Layout.fillWidth: true
            Layout.topMargin: 10
            wrapMode: Text.WordWrap
            color: Appearance.colors.colSubtext
            text: [
                Translation.tr("Resolution / refresh rate: Select a display and choose a supported combination under Modes."),
                Translation.tr("Scale: 1.00 = 100%, 1.25 = 125%, 1.50 = 150%, 2.00 = 200%. A larger scale makes text and windows larger."),
                Translation.tr("Aspect ratio is determined by resolution. For example, 1920×1080 is 16:9. Use your display's native aspect ratio where possible."),
                Translation.tr("Display layout: Drag the display rectangles to reposition them. You can also configure rotation, mirroring and workspace assignments."),
                Translation.tr("Confirm after applying changes. If you do not confirm within %1 seconds, the previous configuration is restored. Confirmed settings are kept for your next login.").arg(15)
            ].map(line => "• " + line).join("\n")
        }
    }
}
