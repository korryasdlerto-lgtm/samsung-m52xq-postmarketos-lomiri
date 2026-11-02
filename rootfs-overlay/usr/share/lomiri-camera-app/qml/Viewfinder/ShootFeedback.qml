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
import Lomiri.Components 1.3

Rectangle {
	id: shootFeedback
	anchors.fill: parent
	color: "black"
	visible: opacity != 0.0
	opacity: 0.0

	function start() {
		shootFeedback.opacity = 1.0;
		shootFeedbackAnimation.restart();
	}

	OpacityAnimator {
		id: shootFeedbackAnimation
		target: shootFeedback
		from: 1.0
		to: 0.0
		duration: LomiriAnimation.SnapDuration
		easing: LomiriAnimation.StandardEasing
	}
}
