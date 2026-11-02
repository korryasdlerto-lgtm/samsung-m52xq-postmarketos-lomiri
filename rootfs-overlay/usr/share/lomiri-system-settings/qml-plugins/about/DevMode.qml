/*
 * This file is part of system-settings
 *
 * Copyright (C) 2014 Canonical Ltd.
 * Copyright (C) 2020 UBports Foundation
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author: Oliver Grawert <ogra@ubuntu.com>
 *
 */

import QtQuick 2.12
import Qt.labs.folderlistmodel 1.0
import GSettings 1.0
import SystemSettings 1.0
import SystemSettings.ListItems 1.0 as SettingsListItems
import Lomiri.Components 1.3
import Lomiri.SystemSettings.SecurityPrivacy 1.0
import Lomiri.SystemSettings.StorageAbout 1.0
import Lomiri.SystemSettings.Usb 1.0

ItemPage {
    id: devModePage
    objectName: "devModePage"
    title: i18n.tr("Developer Mode")
    flickable: scrollWidget

    LomiriSecurityPrivacyPanel {
        id: securityPrivacy
    }

    GSettings {
        id: lomiriSettings
        schema.id: "com.lomiri.Shell"
    }

    onActiveChanged: devModeSwitch.checked = UsbConfig.adbEnabled

    Flickable {
        id: scrollWidget
        anchors.fill: parent

        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > devModePage.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
        /* Set the direction to workaround https://bugreports.qt-project.org/browse/QTBUG-31905
           otherwise the UI might end up in a situation where scrolling doesn't work */
        flickableDirection: Flickable.VerticalFlick

        Column {
            anchors.left: parent.left
            anchors.right: parent.right

            ListItem {
                objectName: "devModeWarningItem"
                height: warningColumn.childrenRect.height + units.gu(2)

                Column {
                    anchors.fill: parent
                    anchors.topMargin: units.gu(1)

                    id: warningColumn
                    spacing: units.gu(2)
                    Icon {
                        id: warnIcon
                        width: parent.width/4
                        height: width
                        name: "security-alert"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        id: warnText
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: i18n.tr("In Developer Mode, anyone can access, change or delete anything on this device by connecting it to another device.")
                    }
                }
            }

            SettingsListItems.Standard {
                visible: UsbConfig.developerModeCapable
                enabled: securityPrivacy.securityType !== LomiriSecurityPrivacyPanel.Swipe
                text: i18n.tr("Developer Mode")
                Switch {
                    id: devModeSwitch
                    checked: UsbConfig.adbEnabled
                    onClicked: UsbConfig.adbEnabled = checked
                }
            }

            SettingsListItems.Standard {
                visible: SystemInfo.supportsRebootToRecovery
                text: i18n.tr("Show Restart to Recovery in the power dialog")
                Switch {
                    checked: lomiriSettings.enableRebootToRecovery === true
                    onClicked: lomiriSettings.enableRebootToRecovery = checked
                }
            }

            ListItem {
                visible: securityPrivacy.securityType == LomiriSecurityPrivacyPanel.Swipe
                height: lockSecurityLabel.height + units.gu(2)
                Label {
                    id: lockSecurityLabel
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: i18n.tr("You need a passcode or passphrase set to use Developer Mode.")
                }
            }

            SettingsListItems.SingleValueProgression {
                visible: securityPrivacy.securityType == LomiriSecurityPrivacyPanel.Swipe
                objectName: "lockSecurityItem"
                text: i18n.tr("Lock security")
                onClicked: pageStack.addPageToNextColumn(
                    devModePage,
                    Qt.resolvedUrl("../security-privacy/LockSecurity.qml"),
                    {securityPrivacy: securityPrivacy}
                )
            }
        }
    }
}

