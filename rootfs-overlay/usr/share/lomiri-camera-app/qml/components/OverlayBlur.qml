/*
 * Copyright (C) 2014 Canonical Ltd.
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
import QtGraphicalEffects 1.0

FastBlur {
    id: overlayBlurEffect

    property var overlayItem
    property var backgroundItem
    property alias live: overlayBlurShader.live
    property var offset: Qt.point(0,0)
    property alias recursive: overlayBlurShader.recursive

    anchors.fill:parent

    QtObject {
        id:_internal
        property var overlayItemToGlobal: overlayBlurEffect.overlayItem  ?  overlayBlurEffect.overlayItem.mapToGlobal(offset.x,offset.y) : Qt.point(0,0);
        property var overlayToBackgroundMapping: overlayBlurEffect.backgroundItem  ? overlayBlurEffect.backgroundItem.mapFromGlobal(overlayItemToGlobal.x,overlayItemToGlobal.y) : Qt.point(0,0);

        function updateOverlayMapping() {
            _internal.overlayItemToGlobal = Qt.binding(function() {return overlayBlurEffect.overlayItem.mapToGlobal(offset.x,offset.y); });
        }

        function updateBkMapping() {
            _internal.overlayToBackgroundMapping = Qt.binding(function() {return  backgroundItem.mapFromGlobal(overlayItemToGlobal.x,overlayItemToGlobal.y);});
        }

    }

    Component.onCompleted: overlayBlurShader.updateRect();

    onOverlayItemChanged: overlayBlurShader.updateRect();
    onBackgroundItemChanged: overlayBlurShader.updateRect();

    Connections {
        target:overlayItem
        onXChanged: overlayBlurShader.updateRect();
        onYChanged: overlayBlurShader.updateRect();
        onWidthChanged: overlayBlurShader.updateRect();
        onHeightChanged: overlayBlurShader.updateRect();
        onScaleChanged: overlayBlurShader.updateRect();
    }

    Connections {
        target:backgroundItem
        onXChanged: overlayBlurShader.updateRect();
        onYChanged: overlayBlurShader.updateRect();
        onWidthChanged: overlayBlurShader.updateRect();
        onHeightChanged: overlayBlurShader.updateRect();
        onScaleChanged: overlayBlurShader.updateRect();
    }

    onOffsetChanged: overlayBlurShader.updateRect();

    radius:units.gu(3)
    source:  ShaderEffectSource {
        id:overlayBlurShader
        clip: true
        sourceItem: backgroundItem

        recursive: false

        function updateRect() {
            _internal.updateOverlayMapping();
            _internal.updateBkMapping();
            if(_internal.overlayToBackgroundMapping && overlayItem) {
                sourceRect = Qt.binding(function() {
                    return  Qt.rect(    _internal.overlayToBackgroundMapping.x,
                                        _internal.overlayToBackgroundMapping.y,
                                        overlayItem.width,
                                        overlayItem.height );
                });
            }
        }
    }
}
