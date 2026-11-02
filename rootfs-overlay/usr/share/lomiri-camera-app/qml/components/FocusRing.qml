/*
 * m52xq: focus square (like Megapixels / plasma-camera): a thin white square that shrinks onto the touched point,
 * stays for a moment and fades out. Same interface as the original ring (center, show()).
 */

import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: focusRing

    property point center
    function show() {
        hideTimer.restart();
        opacity = 1.0;
        shrink.restart();
    }

    x: center.x - width / 2.0
    y: center.y - height / 2.0
    width: units.gu(9)
    height: units.gu(9)

    opacity: 0.0
    Behavior on opacity { LomiriNumberAnimation {} }

    Rectangle {
        id: square
        anchors.fill: parent
        color: "transparent"
        border.color: "white"
        border.width: units.dp(2)
        // darker thin edge keeps the square visible on bright scenes
        Rectangle {
            anchors.fill: parent
            anchors.margins: -units.dp(1)
            color: "transparent"
            border.color: "#66000000"
            border.width: units.dp(1)
            z: -1
        }
        // short ticks in the middle of every side
        Repeater {
            model: 4
            Rectangle {
                width: index % 2 === 0 ? units.dp(2) : units.gu(1)
                height: index % 2 === 0 ? units.gu(1) : units.dp(2)
                color: "white"
                x: index === 0 || index === 2 ? parent.width / 2 - width / 2 : (index === 1 ? parent.width - width : 0)
                y: index === 1 || index === 3 ? parent.height / 2 - height / 2 : (index === 2 ? parent.height - height : 0)
            }
        }
    }

    ScaleAnimator {
        id: shrink
        target: focusRing
        from: 1.4
        to: 1.0
        duration: LomiriAnimation.FastDuration
        easing: LomiriAnimation.StandardEasing
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: focusRing.opacity = 0.0;
    }
}
