// SPDX-FileCopyrightText: 2015 Marco Martin <mart@kde.org>
// SPDX-License-Identifier: LGPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.telephony
import org.kde.people as KPeople

Controls.ItemDelegate {
    id: root

    highlighted: false
    onClicked: applicationWindow().call(model.communicationWith)

    // m52xq: which SIM the call went over. History.account is the ICCID of the SIM, /run/m52xq-sim-slots (m52xq-sim-slots.service)
    // maps the ICCIDs of the inserted SIMs to their slot ("ICCID N" per line); needs QML_XHR_ALLOW_FILE_READ=1 in the launcher
    // the name of the contact (KPeople) of the number, shown above the number
    property string contactUri: ContactUtils.phoneNumberToContactUri(model.communicationWith)
    KPeople.PersonData {
        id: personData
        personUri: root.contactUri
    }
    readonly property string contactName: root.contactUri !== "" ? String(personData.person.name || "") : ""

    property string simSlot: {
        const acc = String(model.account || "");
        if (!acc)
            return "";
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file:///run/m52xq-sim-slots", false);
        try {
            xhr.send();
        } catch (e) {
            return "";
        }
        const lines = (xhr.responseText || "").split("\n");
        for (let i = 0; i < lines.length; ++i) {
            const f = lines[i].trim().split(" ");
            if (f.length === 2 && f[0] === acc)
                return f[1];
        }
        return "";
    }

    contentItem: RowLayout {
        Kirigami.Icon {
            width: Kirigami.Units.iconSizes.medium
            height: width
            color: source == "call-incoming" ? "blue" :
                    source == "call-missed" ? "red" :
                    source == "call-outgoing" ? "green" : Kirigami.Theme.textColor
            source: {
                if (model.direction == DialerTypes.CallDirection.Incoming) {
                    if (model.duration > 0)
                        return "call-incoming";
                    else
                        return "call-missed";
                } else {
                    if (model.direction == DialerTypes.CallDirection.Outgoing)
                        return "call-outgoing";
                    else
                        return "call-start";
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            Controls.Label {
                id: callContactDisplayLabel

                text: root.contactName !== "" ? root.contactName : model.communicationWith
                Layout.fillWidth: true
            }

            Controls.Label {
                id: numberLabel

                visible: callContactDisplayLabel.text !== text
                text: ContactUtils.displayString(model.communicationWith)
                Layout.fillWidth: true
            }

        }

        ColumnLayout {
            Layout.fillWidth: true

            Controls.Label {
                Layout.alignment: Qt.AlignRight
                text: (root.simSlot ? "SIM " + root.simSlot + "  ·  " : "") + Qt.formatDateTime(model.startedAt, Qt.locale().dateTimeFormat(Locale.ShortFormat))
            }

            Controls.Label {
                Layout.alignment: Qt.AlignRight
                text: i18n("Duration: %1", secondsToTimeString(model.duration))
                visible: model.duration > 0
            }

        }

    }

}
