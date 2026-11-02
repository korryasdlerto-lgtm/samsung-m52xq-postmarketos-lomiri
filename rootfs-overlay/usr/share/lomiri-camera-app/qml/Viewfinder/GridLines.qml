/*
 * <one line to give the program's name and a brief idea of what it does.>
 * Copyright (C) 2019  eran <email>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
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
	id: gridlines
	objectName: "gridlines"
	anchors.fill:parent

	property color color: Qt.rgba(0.8, 0.8, 0.8, 0.8)
	property real thickness: units.dp(1)

	Rectangle {
		y: parent.height / 3
		width: parent.width
		height: gridlines.thickness
		color: gridlines.color
	}

	Rectangle {
		y: 2 * parent.height / 3
		width: parent.width
		height: gridlines.thickness
		color: gridlines.color
	}

	Rectangle {
		x: parent.width / 3
		width: gridlines.thickness
		height: parent.height
		color: gridlines.color
	}

	Rectangle {
		x: 2 * parent.width / 3
		width: gridlines.thickness
		height: parent.height
		color: gridlines.color
	}
}
