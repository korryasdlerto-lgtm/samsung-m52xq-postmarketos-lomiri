import QtQuick 2.12
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import QtSensors 5.4

Page {
    id:_infoPage

    signal back();

    height: parent.height ;//infoHeader.height + aboutCloumn.height + infoLinksList.height

    header: PageHeader {
        id:infoHeader
        StyleHints {
            backgroundColor:"transparent"
            foregroundColor: theme.palette.normal.backgroundText
        }

        title: i18n.tr("About")

        leadingActionBar.actions: [
               Action {
                   iconName: "back"
                   text: i18n.tr("Back")
                   onTriggered: _infoPage.back();
               }
           ]
    }

    property bool portrait: (Screen.orientation == Qt.PortraitOrientation || Screen.orientation == Qt.InvertedPortraitOrientation)

    transitions: [
        Transition {
            NumberAnimation { properties: "width,height,x,y"; duration: LomiriAnimation.FastDuration}
        }
    ]

    states: [
        State {
            name: "landscape"
            when: !infoPage.portrait

            PropertyChanges {
                target: aboutCloumn
                width: parent.width/2
            }

            AnchorChanges {
                target: aboutCloumn
                anchors {
                    top:infoHeader.bottom
                    left: parent.left
                    right: undefined
                    bottom:parent.bottom
                }
            }

            AnchorChanges {
                target: infoLinksList
                anchors {
                    top:infoHeader.bottom
                    left: aboutCloumn.right
                    right: parent.right
                    bottom:parent.bottom
                }
            }
        }
    ]

    ListModel {
        id: infoModel
    }

    Component.onCompleted: {
        infoModel.append({ name: i18n.tr("Get the source"), url: "https://gitlab.com/ubports/development/apps/lomiri-camera-app" })
        infoModel.append({ name: i18n.tr("Report issues"), url: "https://gitlab.com/ubports/development/apps/lomiri-camera-app/issues" })
        infoModel.append({ name: i18n.tr("Help translate"), url: "https://translate.ubports.com/projects/ubports/lomiri-camera-app/" })
    }

    Column {
        id: aboutCloumn
        anchors.top: infoHeader.bottom
        anchors.topMargin: units.gu(2)
        spacing:units.dp(2)
        width:parent.width
        height:units.gu(33)

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            height: Math.min(parent.width/2, parent.height/2)
            width:height
            source:"../../assets/lomiri-camera-app.svg"
            layer.enabled: true
            layer.effect: LomiriShapeOverlay {
                relativeRadius: 0.75
            }
        }

        Label {
            width: parent.width
            font.pixelSize: units.gu(5)
            font.bold: true
            color: theme.palette.normal.backgroundText
            horizontalAlignment: Text.AlignHCenter
            text: i18n.tr("Camera")
        }
        Label {
            width: parent.width
            color: theme.palette.normal.backgroundSecondaryText
            horizontalAlignment: Text.AlignHCenter
            text: i18n.tr("Version %1").arg(Qt.application.version)
        }

    }

    LomiriListView {
        id:infoLinksList
        height:units.gu(35)
        anchors {
            top: aboutCloumn.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        currentIndex: -1
        interactive: false

         model :infoModel
         delegate: ListItem {
             highlightColor:theme.palette.highlighted.backgroundText
             ListItemLayout {
                title.text : model.name
                title.color: theme.palette.normal.backgroundText
                Icon {
                   width:units.gu(2)
                   name:"go-next"
               }
            }

            onClicked: Qt.openUrlExternally(model.url)

         }
    }

}
