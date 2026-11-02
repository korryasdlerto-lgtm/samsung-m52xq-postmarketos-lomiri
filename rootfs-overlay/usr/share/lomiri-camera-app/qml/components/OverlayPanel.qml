/*
 * Copyright (C) 2019 UBports Foundation
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

Item {
	id:_overlayPanel
	property var overlayItem
	property var  anchorTo: null

    anchors.fill: anchorTo ? anchorTo : overlayItem

	property alias blur: _overlayBlur
	property alias tint: _overlayTint

	 OverlayBlur {
		id:_overlayBlur
		 anchors.fill:parent

		 overlayItem:_overlayPanel.overlayItem
        z:-1
    }

    OverlayTint {
		id:_overlayTint
		anchors.fill:parent
	}

}
