import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: root
    forceWidth: true

    // Path to the profile manager script (lives next to switchwall.sh).
    readonly property string scriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/theme-profile.sh`

    // Parsed list of saved profiles.
    property var profiles: []
    property string statusMessage: ""
    // Name currently awaiting delete confirmation (two-step delete).
    property string pendingDelete: ""

    function refresh() {
        listProc.exec(["bash", "-c", `"${root.scriptPath}" list --json`]);
    }

    function save(name) {
        const trimmed = (name || "").trim();
        if (trimmed.length === 0) {
            root.statusMessage = Translation.tr("Please enter a profile name");
            return;
        }
        root.statusMessage = Translation.tr("Saving…");
        saveProc.exec(["bash", "-c", `"${root.scriptPath}" save ${JSON.stringify(trimmed)}`]);
    }

    function applyProfile(name) {
        root.statusMessage = Translation.tr("Applying '%1'…").arg(name);
        applyProc.profileName = name;
        applyProc.exec(["bash", "-c", `"${root.scriptPath}" apply ${JSON.stringify(name)}`]);
    }

    function requestDelete(name) {
        if (root.pendingDelete === name) {
            root.pendingDelete = "";
            deleteProc.exec(["bash", "-c", `"${root.scriptPath}" delete ${JSON.stringify(name)}`]);
        } else {
            root.pendingDelete = name;
        }
    }

    function renameProfile(oldName, newName) {
        const trimmed = (newName || "").trim();
        if (trimmed.length === 0 || trimmed === oldName) return;
        renameProc.exec(["bash", "-c", `"${root.scriptPath}" rename ${JSON.stringify(oldName)} ${JSON.stringify(trimmed)}`]);
    }

    Component.onCompleted: root.refresh()

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.profiles = JSON.parse(text.trim() || "[]");
                } catch (e) {
                    root.profiles = [];
                }
            }
        }
    }

    Process {
        id: saveProc
        onExited: (exitCode, exitStatus) => {
            root.statusMessage = exitCode === 0
                ? Translation.tr("Profile saved")
                : Translation.tr("Could not save profile");
            root.refresh();
        }
    }

    Process {
        id: applyProc
        property string profileName: ""
        onExited: (exitCode, exitStatus) => {
            root.statusMessage = exitCode === 0
                ? Translation.tr("Applied '%1'").arg(applyProc.profileName)
                : Translation.tr("Could not apply '%1'").arg(applyProc.profileName);
            root.refresh();
        }
    }

    Process {
        id: deleteProc
        onExited: (exitCode, exitStatus) => {
            root.statusMessage = exitCode === 0
                ? Translation.tr("Profile deleted")
                : Translation.tr("Could not delete profile");
            root.refresh();
        }
    }

    Process {
        id: renameProc
        onExited: (exitCode, exitStatus) => root.refresh()
    }

    ContentSection {
        icon: "bookmarks"
        title: Translation.tr("Style Profiles")

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            text: Translation.tr("A profile saves your whole look at once: wallpaper, colors (Material You), dark/light mode, desktop widgets layout and appearance settings. Apply it to switch back to a saved style.")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialTextField {
                id: newProfileField
                Layout.fillWidth: true
                placeholderText: Translation.tr("New profile name…")
                onAccepted: {
                    root.save(text);
                    text = "";
                }
            }

            RippleButton {
                buttonText: Translation.tr("Save current style")
                onClicked: {
                    root.save(newProfileField.text);
                    newProfileField.text = "";
                }
            }

            RippleButton {
                buttonText: Translation.tr("Refresh")
                onClicked: root.refresh()
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.statusMessage.length > 0
            color: Appearance.colors.colSubtext
            text: root.statusMessage
        }
    }

    ContentSection {
        icon: "folder_copy"
        title: Translation.tr("Saved profiles")

        StyledText {
            Layout.fillWidth: true
            visible: root.profiles.length === 0
            color: Appearance.colors.colSubtext
            text: Translation.tr("No profiles yet. Save your current style above to create one.")
        }

        Repeater {
            model: root.profiles
            delegate: StyledRectangle {
                id: profileCard
                required property var modelData
                required property int index

                readonly property bool confirmingDelete: root.pendingDelete === profileCard.modelData.name

                Layout.fillWidth: true
                implicitHeight: cardContent.implicitHeight + 20
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                RowLayout {
                    id: cardContent
                    anchors {
                        fill: parent
                        margins: 10
                    }
                    spacing: 12

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 54

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colLayer2
                        }

                        StyledImage {
                            id: previewImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(96, 54)
                            source: {
                                const wp = profileCard.modelData.wallpaper || "";
                                if (wp.startsWith("__PROFILE__/")) {
                                    return Qt.resolvedUrl(`${FileUtils.trimFileProtocol(Directories.shellConfig)}/theme-profiles/${profileCard.modelData.name}/${wp.substring("__PROFILE__/".length)}`);
                                }
                                return Qt.resolvedUrl(wp);
                            }
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: previewImage.width
                                    height: previewImage.height
                                    radius: Appearance.rounding.small
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        MaterialTextField {
                            id: renameField
                            Layout.fillWidth: true
                            text: profileCard.modelData.name
                            onAccepted: {
                                root.renameProfile(profileCard.modelData.name, renameField.text);
                                renameField.text = profileCard.modelData.name;
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.colors.colSubtext
                            text: {
                                const m = profileCard.modelData;
                                const mode = m.mode === "light" ? Translation.tr("Light") : Translation.tr("Dark");
                                const type = (m.type && m.type !== "auto") ? m.type.replace("scheme-", "") : "auto";
                                return `${mode} · ${type}`;
                            }
                            elide: Text.ElideRight
                        }
                    }

                    RippleButton {
                        buttonText: Translation.tr("Apply")
                        onClicked: root.applyProfile(profileCard.modelData.name)
                    }

                    RippleButton {
                        buttonText: profileCard.confirmingDelete
                            ? Translation.tr("Confirm delete?")
                            : Translation.tr("Delete")
                        colBackground: profileCard.confirmingDelete
                            ? Appearance.colors.colError
                            : Appearance.colors.colErrorContainer
                        colBackgroundHover: Appearance.colors.colErrorContainerHover
                        onClicked: root.requestDelete(profileCard.modelData.name)
                    }
                }
            }
        }
    }
}
