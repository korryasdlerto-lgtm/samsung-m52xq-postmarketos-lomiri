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
import QtMultimedia 5.0
import QtSensors 5.2
import Lomiri.Components 1.3
import UserMetrics 0.1
import Lomiri.Content 1.3
import CameraApp 0.1
import Qt.labs.settings 1.0
import QZXing 3.3

import "components"
import "Viewfinder"

Window {
    id: main
    objectName: "main"
    // m52xq: on the phone the window is the screen (see camera-app.qml)
    width: application.desktopMode ? Math.min(Screen.width, height * viewFinderView.aspectRatio) : Screen.width
    height: application.desktopMode ? Math.min(Screen.height, units.gu(80)) : Screen.height
    color: "black"

    // m52xq: the screen rotation from the accelerometer (Screen.orientation stays portrait on wayland)
    OrientationSensor {
        id: m52xqOrientationSensor
        active: true
    }
    readonly property int m52xqScreenAngle: application.desktopMode ? Screen.angleBetween(Screen.primaryOrientation, Screen.orientation) : 0
    readonly property int m52xqWindowAngle: (viewFinderView.width > viewFinderView.height)
                                            ? ((m52xqDeviceAngle == 90 || m52xqDeviceAngle == 270) ? m52xqDeviceAngle : 90)
                                            : (m52xqDeviceAngle == 180 ? 180 : 0)
    readonly property int m52xqDeviceAngle: {
        if (!m52xqOrientationSensor.reading)
            return 0;
        switch (m52xqOrientationSensor.reading.orientation) {
        case OrientationReading.LeftUp: return 90;
        case OrientationReading.TopDown: return 180;
        case OrientationReading.RightUp: return 270;
        default: return 0;
        }
    }
    title: i18n.tr("Camera")
    // special flag only supported by Unity8/MIR so far that hides the shell's
    // top panel in Staged mode
    flags: Qt.Window | 0x00800000

      Settings {
        id: appSettings

        property bool blurEffects:true
        property bool blurEffectsPreviewOnly: true
      }

    property int preFullScreenVisibility

    function toggleFullScreen() {
        if (main.visibility != Window.FullScreen) {
            preFullScreenVisibility = main.visibility;
            main.visibility = Window.FullScreen;
        } else {
            main.visibility = preFullScreenVisibility;
        }
    }

    function exitFullScreen() {
        if (main.visibility == Window.FullScreen) {
            main.visibility = preFullScreenVisibility;
        }
    }

    Component.onCompleted: {
        i18n.domain = "lomiri-camera-app";
        i18n.bindtextdomain("lomiri-camera-app", i18nDirectory);
        main.show();
    }

    QZXingFilter {
        id: qrCodeScanner
        orientation: viewFinderView.finderOverlay.sensorOrientation

        active: true
        decoder {
            enabledDecoders: QZXing.DecoderFormat_QR_CODE
            imageSourceFilter: QZXing.SourceFilter_ImageNormal |
                               QZXing.SourceFilter_ImageInverted

            onTagFoundAdvanced: {
                viewFinderView.recentlyScannedTag = tag
            }
        }
    }

    ViewFinderView {
        id: viewFinderView
        anchors.fill: parent
        overlayVisible: true
        inView: true
        focus: true
        opacity: inView ? 1.0 : 0.0
        readOnly: true
        cameraFilters: [ qrCodeScanner ]
    }

    property bool contentExportMode: transfer !== null
    property var transfer: null
    property var transferContentType: transfer ? transfer.contentType : "image"

    function exportContent(urls) {
        if (!main.transfer) return;

        var item;
        var items = [];
        for (var i=0; i<urls.length; i++) {
            item = contentItemComponent.createObject(main.transfer, {"url": urls[i]});
            items.push(item);
        }
        main.transfer.items = items;
        main.transfer.state = ContentTransfer.Charged;
        main.transfer = null;
    }

    function cancelExport() {
        main.transfer.state = ContentTransfer.Aborted;
        main.transfer = null;
    }

    Component {
        id: contentItemComponent
        ContentItem {
        }
    }
}
