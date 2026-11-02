import QtQuick 2.12
import SystemSettings 1.0
import SystemSettings.ListItems 1.0 as SettingsListItems
import Lomiri.Components 1.3
import Lomiri.SystemSettings.StorageAbout 1.0

ItemPage {
    id: licensesPage
    objectName: "licensesPage"
    title: i18n.tr("Software licenses")
    flickable: softwareList

    LomiriStorageAboutPanel {
        id: backendInfo
    }

    ListView {
        id: softwareList
        anchors.fill: parent

        /* m52xq: no /usr/share/doc/<package>/copyright on Alpine: the installed apk packages with their licences */
        model: backendInfo.m52xqPackages()
        delegate: SettingsListItems.SingleValueProgression {
            text: modelData.name
            value: modelData.license
            onClicked: pageStack.addPageToNextColumn(
                licensesPage, Qt.resolvedUrl("License.qml"), {binary: modelData.name}
            )
        }

        Component.onCompleted: {
            var scaleFactor = units.gridUnit / 8;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }
    }
}
