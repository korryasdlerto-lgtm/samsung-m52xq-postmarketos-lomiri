/*
 * Copyright 2015 Canonical Ltd.
 * Copyright (C) 2025 UBports Foundation
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
import Lomiri.Components 1.3

Item {
    property string videoPath
    property int bottomMargin

    Image {
        id: thumbnail
        anchors.fill: parent

        fillMode: Image.PreserveAspectFit
        sourceSize.width: width
        sourceSize.height: height

        source: videoPath ? "image://thumbnailer/%1".arg(videoPath) : ""
        opacity: status == Image.Ready ? 1.0 : 0.0
        Behavior on opacity { LomiriNumberAnimation { duration: LomiriAnimation.FastDuration } }
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: parent.bottomMargin

        ActivityIndicator {
            anchors.centerIn: parent
            visible: running
            running: thumbnail.status == Image.Loading
        }

        PlayIcon {
            anchors.centerIn: parent
            width: units.gu(7)
            height: width
        }

        MouseArea {
            anchors.centerIn: parent
            width: units.gu(10)
            height: units.gu(10)
            onClicked: Qt.openUrlExternally("video://%1".arg(videoPath));
        }
    }
}
