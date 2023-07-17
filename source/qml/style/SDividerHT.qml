import QtQuick 2.15

import gui 1.0

Rectangle {
    id: root
    anchors.left: parent.left
    anchors.right: parent.right
    required property int minOffset
    required property int maxOffset
    required property int offset
    y: snapping ? Math.floor(snap) : offset
    height: 5
    color: COMMON.bg4

    property bool locked: true
    property bool snapping: false
    property var snap: null
    property var wasSnapped: false
    property var initialOffset: 0
    property var snapSize: 50
    property var overflow: 3

    onOffsetChanged: {
        if(snap - offset == 0.0) {
            root.offset = Qt.binding(function() {return snap})
            root.locked = true
        }
    }

    property var limited: false
    function setLimited(current) {
        if(current != limited) {
            limited = current
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -root.overflow
        anchors.bottomMargin: -root.overflow

        hoverEnabled: true
        property var startPosition: Qt.point(0,0)
        property var startOffset: 0
        onPressed: {
            startPosition = mapToGlobal(mouse.x, mouse.y)
            startOffset = root.offset
            root.initialOffset = root.offset
            root.setLimited(false)
            root.wasSnapped = (Math.abs(snap - offset) == 0)
        }
        onPositionChanged: {
            if(pressedButtons) {
                root.locked = false

                var absMouse = mapToGlobal(mouse.x, mouse.y)
                var delta = Qt.point(startPosition.x-absMouse.x, startPosition.y-absMouse.y)
                var mouseOffset = startOffset - delta.y
                parent.offset = Math.min(parent.maxOffset, Math.max(parent.minOffset, mouseOffset))

                if(parent.offset == parent.maxOffset && Math.abs(parent.maxOffset - mouseOffset) > 400) {
                    root.setLimited(true)
                } else {
                    root.setLimited(false)
                }

                if(snap != null) {
                    if(!root.wasSnapped) {
                        root.snapping = (Math.abs(snap - offset) < snapSize)
                    } else if (Math.abs(root.initialOffset - offset) > snapSize) {
                        root.wasSnapped = false
                    }
                }
            }
        }
        onReleased: {
            root.setLimited(false)
            if(snap == null) {
                return
            }
            if(Math.abs(snap - offset) < 50) {
                root.offset = Qt.binding(function() {return snap})
                root.locked = true
            }
        }
    }

    onMaxOffsetChanged: {
        if(!root.locked && parent && parent.height > 0 && y > 0)
            offset = Math.min(maxOffset, Math.max(minOffset, offset))
    }
}