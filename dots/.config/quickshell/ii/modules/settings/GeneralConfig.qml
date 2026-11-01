import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        id: root
        icon: "lock_clock"
        title: Translation.tr("Lock screen and display")
        property bool loaded: false
        property string revision: ""
        property int feedback: 0
        property bool saving: false
        readonly property bool busy: settingsProcess.running
    
        function refresh() {
            if (root.busy) return;
            root.saving = false;
            root.feedback = 0;
            settingsProcess.command = ["python3", Quickshell.shellPath("scripts/settings/idle-settings.py"), "status"];
            settingsProcess.running = true;
        }
        function apply() {
            if (!root.loaded || root.busy) return;
            root.saving = true;
            root.feedback = 0;
            settingsProcess.command = ["python3", Quickshell.shellPath("scripts/settings/idle-settings.py"), "apply",
                root.revision, lockEnabled.checked ? "1" : "0", String(lockMinutes.value),
                displayEnabled.checked ? "1" : "0", String(displayMinutes.value)];
            settingsProcess.running = true;
        }
        Component.onCompleted: refresh()
    
        component TimeoutRow: RowLayout {
            property string text
            property alias value: minutes.value
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 10
            MaterialSymbol {
                text: "timer"
                iconSize: Appearance.font.pixelSize.larger
                opacity: parent.enabled ? 1 : 0.4
            }
            StyledText {
                Layout.fillWidth: true
                text: parent.text
                color: Appearance.colors.colOnSecondaryContainer
                opacity: parent.enabled ? 1 : 0.4
            }
            StyledSpinBox {
                id: minutes
                from: 1
                to: 1440
                implicitWidth: 140
                implicitHeight: baseHeight
                leftPadding: baseHeight
                rightPadding: baseHeight
                topPadding: 0
                bottomPadding: 0
            }
        }
    
        Process {
            id: settingsProcess
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const state = JSON.parse(text);
                        if (!state.ok) throw new Error("Idle settings unavailable");
                        lockEnabled.checked = state.lockEnabled;
                        lockMinutes.value = state.lockMinutes;
                        displayEnabled.checked = state.displayEnabled;
                        displayMinutes.value = state.displayMinutes;
                        root.revision = state.revision;
                        root.loaded = true;
                        root.feedback = root.saving ? 1 : 0;
                    } catch (e) { root.feedback = 2; }
                }
            }
            onExited: (code, status) => { if (code !== 0) root.feedback = 2; }
        }
    
        ConfigSwitch {
            id: lockEnabled
            objectName: "idleLockEnabled"
            buttonIcon: "lock"
            text: Translation.tr("Automatic screen lock")
            enabled: root.loaded && !root.busy
        }
        TimeoutRow {
            id: lockMinutes
            objectName: "idleLockMinutes"
            text: Translation.tr("Lock after (minutes)")
            value: 5
            enabled: root.loaded && lockEnabled.checked && !root.busy
            Layout.fillWidth: true
        }
        ConfigSwitch {
            id: displayEnabled
            objectName: "idleDisplayEnabled"
            buttonIcon: "desktop_windows"
            text: Translation.tr("Automatically turn off displays")
            enabled: root.loaded && !root.busy
        }
        TimeoutRow {
            id: displayMinutes
            objectName: "idleDisplayMinutes"
            text: Translation.tr("Turn off after (minutes)")
            value: 10
            enabled: root.loaded && displayEnabled.checked && !root.busy
            Layout.fillWidth: true
        }
        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: Translation.tr("Times are measured from the last input. Turning off displays does not suspend the computer.")
        }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            RippleButtonWithIcon {
                materialIcon: "refresh"
                mainText: Translation.tr("Refresh")
                enabled: !root.busy
                onClicked: root.refresh()
            }
            RippleButtonWithIcon {
                objectName: "idleApply"
                materialIcon: "check"
                mainText: Translation.tr("Apply")
                enabled: root.loaded && !root.busy
                onClicked: root.apply()
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.feedback !== 0
            wrapMode: Text.WordWrap
            color: root.feedback === 1 ? Appearance.colors.colSubtext : Appearance.colors.colError
            text: root.feedback === 1
                ? Translation.tr("Lock and display settings applied.")
                : Translation.tr("Could not apply or read idle settings. Refresh and try again.")
        }
    }
    

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}
