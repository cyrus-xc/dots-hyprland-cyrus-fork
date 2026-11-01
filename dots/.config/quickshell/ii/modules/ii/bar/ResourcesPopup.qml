import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    keepOnScreen: true

    function quantity(value, digits, suffix) {
        return value === null || value === undefined ? Translation.tr("Not supported") : Number(value).toFixed(digits) + suffix;
    }
    function load(value) {
        return value === null || value === undefined ? "—" : Math.round(value*100) + "%";
    }
    function clock(value) { return root.quantity(value === null ? null : value/1000, 2, " GHz"); }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Row {
            spacing: 16
            Column {
                width: 220
                spacing: 8
                StyledPopupHeaderRow { icon: "memory"; label: "RAM" }
                Column {
                    width: parent.width
                    spacing: 4
                    StyledPopupValueRow {
                        width: parent.width
                        icon: "clock_loader_60"
                        label: Translation.tr("Used:")
                        value: (ResourceUsage.memoryUsed/1048576).toFixed(1) + " GiB"
                    }
                    StyledPopupValueRow {
                        width: parent.width
                        icon: "check_circle"
                        label: Translation.tr("Free:")
                        value: (ResourceUsage.memoryFree/1048576).toFixed(1) + " GiB"
                    }
                    StyledPopupValueRow {
                        width: parent.width
                        icon: "empty_dashboard"
                        label: Translation.tr("Total:")
                        value: (ResourceUsage.memoryTotal/1048576).toFixed(1) + " GiB"
                    }
                }
            }
            Repeater {
                model: ResourceUsage.cpuPackages
                delegate: Column {
                    required property var modelData
                    width: 220
                    spacing: 8
                    StyledPopupHeaderRow { icon: "planner_review"; label: "CPU" + modelData.id }
                    Column {
                        width: parent.width
                        spacing: 4
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "speed"
                            label: Translation.tr("Load:")
                            value: root.load(modelData.usage)
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "bolt"
                            label: Translation.tr("Power:")
                            value: root.quantity(modelData.powerWatts, 1, " W")
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "speed"
                            label: Translation.tr("Frequency:")
                            value: root.clock(modelData.frequencyMhz)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            visible: ResourceUsage.gpus.length > 0
            color: Appearance.colors.colOutlineVariant
        }
        Grid {
            columns: 2
            spacing: 16
            Repeater {
                model: ResourceUsage.gpus
                delegate: Column {
                    required property var modelData
                    width: 338
                    spacing: 8
                    StyledPopupHeaderRow { icon: "developer_board"; label: "GPU" + modelData.index }
                    StyledText {
                        width: parent.width
                        text: modelData.name
                        wrapMode: Text.WordWrap
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Column {
                        width: parent.width
                        spacing: 4
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "speed"
                            label: Translation.tr("Load:")
                            value: root.load(modelData.usage)
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "thermometer"
                            label: Translation.tr("Temperature:")
                            value: root.quantity(modelData.temperatureC, 0, " °C")
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "bolt"
                            label: Translation.tr("Power:")
                            value: root.quantity(modelData.powerWatts, 1, " W")
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "memory"
                            label: Translation.tr("VRAM:")
                            value: modelData.memoryUsedMib === null || modelData.memoryTotalMib === null ? "—"
                                : (modelData.memoryUsedMib/1024).toFixed(1) + " / " + (modelData.memoryTotalMib/1024).toFixed(1) + " GiB"
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "speed"
                            label: Translation.tr("GPU clock:")
                            value: root.clock(modelData.frequencyMhz)
                        }
                        StyledPopupValueRow {
                            width: parent.width
                            icon: "speed"
                            label: Translation.tr("Memory clock:")
                            value: root.clock(modelData.memoryFrequencyMhz)
                        }
                    }
                }
            }
        }
        StyledText {
            visible: !ResourceUsage.hardwareAvailable
            text: Translation.tr("Hardware metrics unavailable")
            color: Appearance.colors.colSubtext
        }
    }
}
