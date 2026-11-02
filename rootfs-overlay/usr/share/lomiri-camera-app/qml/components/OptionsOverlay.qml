/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Window 2.2
import Lomiri.Components 1.3

Item {
    id: optionsOverlay

    property list<ListModel> options
    property bool valueSelectorOpened: optionValueSelector.caller != null

    function closeValueSelector() {
        optionValueSelector.hide();
    }

    height: optionsGrid.height + optionsGrid.rowSpacing

    Grid {
        id: optionsGrid
        anchors {
            horizontalCenter: parent.horizontalCenter
        }

        columns: 3
        columnSpacing: units.gu(9.5)
        rowSpacing: units.gu(3)

        Repeater {
            model: optionsOverlay.options
            delegate: OptionButton {
                id: optionButton
                model: modelData
                onClicked: optionValueSelector.toggle(model, optionButton)
                enabled: model.available && (!optionValueSelector.caller || optionValueSelector.caller == optionButton)
                opacity: enabled ? 1.0 : 0.05
                Behavior on opacity {LomiriNumberAnimation {duration: LomiriAnimation.FastDuration}}
                customRotation: main.orientedRotationAngle
            }
        }
    }

    ListView {
        id: optionValueSelector
        objectName: "optionValueSelector"
        height: Math.min( contentHeight, screenHeight / 2  )
        snapMode: ListView.SnapToItem
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        rotation: main.orientedRotationAngle
            
        Behavior on rotation {
            RotationAnimator {
                duration: LomiriAnimation.BriskDuration
                easing: LomiriAnimation.StandardEasing
                direction: RotationAnimator.Shortest
            }
        }

        onRotationChanged: if (caller) { alignWith(caller); }

        property OptionButton caller
        // m52xq: Screen.orientation does not change on wayland (Lomiri turns the window itself): the height of the list
        // is taken from the real window (main), otherwise in landscape the upper items (the large resolutions) went off the screen.
        // Not optionsOverlay.height: that is only the strip of the bottom edge (63..336 px) and the list shrank to one item
        property int screenHeight: main.height

        function toggle(model, callerButton) {
            if (optionValueSelectorVisible && optionValueSelector.model === model) {
                hide();
            } else {
                show(model, callerButton);
            }
        }

        function show(model, callerButton) {
            optionValueSelector.caller = callerButton;
            optionValueSelector.model = model;
            alignWith(callerButton);
            optionValueSelectorVisible = true;
            positionViewAtIndex(model.selectedIndex, ListView.Contain);

        }

        function hide() {
            optionValueSelectorVisible = false;
            optionValueSelector.caller = null;
        }

        function alignWith(item) {
            if(model) {
                forceLayout();
                width = contentItem.childrenRect.width;
            }
            // horizontally center optionValueSelector with the center of item
            // if there is enough space to do so, that is as long as optionValueSelector
            // does not get cropped by the edge of the screen
            var itemX = parent.mapFromItem(item, 0, 0).x;
            var centeredX = itemX + item.width / 2.0 - width / 2.0;
            var margin = units.gu(1);
            var offScreenToTheLeft = main.sensorHasDifferentOrientation ? centeredX + width / 2.0 - height / 2.0 < margin
                                                            : centeredX < margin;
            var offScreenToTheRight = main.sensorHasDifferentOrientation ? centeredX  + width / 2.0 + height / 2.0 > optionsOverlay.width - margin
                                                            : centeredX + width > optionsOverlay.width - margin;
            var offScreenOffset = itemX + item.width - width;

            if (offScreenToTheLeft) {
                x = itemX;
            } else if (offScreenToTheRight) {
                x = offScreenOffset;
            } else {
                x = centeredX;
            }

            // vertically position the options above the caller button
            y = Qt.binding(function() { return Math.max(-(screenHeight - (optionsOverlay.height - item.y) - units.gu(2))
                                                            , optionsGrid.y + item.y - (main.sensorHasDifferentOrientation ? height / 2 + width: height) - units.gu(2)) });
        }

        visible: opacity !== 0.0
        onVisibleChanged: if (!visible) model = null;
        opacity: optionValueSelectorVisible ? 1.0 : 0.0
        Behavior on opacity {LomiriNumberAnimation {duration: LomiriAnimation.FastDuration}}

        Connections {
            target: parent
            onWidthChanged: {
                console.log("Flipped");
                if(optionValueSelector.caller) { optionValueSelector.alignWith(optionValueSelector.caller); }
            }
        }

        headerPositioning:  ListView.OverlayHeader
        header: Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(3)
            visible: !optionValueSelector.atYBeginning
            name:"go-up"
        }

        delegate: OptionValueButton {
            anchors.left: parent.left
            columnWidth: optionValueSelector.width

            label: (model && model.label) ? i18n.tr(model.label) : ""

            iconName: (model && model.icon) ? model.icon : ""
            selected: optionValueSelector.model.selectedIndex == index
            Component.onCompleted: {
                if (model && model.iconSource) {
                    iconSource = model.iconSource
                }
            }

            isLast: index === optionValueSelector.count - 1
            onClicked: {
                if (optionValueSelector.model.setSettingProperty) {
                    optionValueSelector.model.setSettingProperty(optionValueSelector.model.get(index).value);
                } else {
                    settings[optionValueSelector.model.settingsProperty] = optionValueSelector.model.get(index).value;
                }
            }
        }

        footerPositioning: ListView.OverlayFooter
        footer: Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(3)
            visible: !optionValueSelector.atYEnd
            name:"go-down"
        }
    }
}
