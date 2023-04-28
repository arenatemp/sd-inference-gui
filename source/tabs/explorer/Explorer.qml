import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1

import gui 1.0

import "../../style"
import "../../components"

Item {
    id: root

    function releaseFocus() {
        parent.releaseFocus()
    }

    Rectangle {
        anchors.fill: column
        color: COMMON.bg0
    }
    Column {
        id: column
        width: 150
        height: parent.height

        SColumnButton {
            label: "Checkpoints"
            property var index: 0
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "checkpoint"
            index: 0
            stack: modelsStack
        }
        SColumnButton {
            label: "Components"
            property var index: 1
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "component"
            index: 1
            stack: modelsStack
        }
        SColumnButton {
            label: "LoRAs"
            property var index: 2
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "lora"
            index: 2
            stack: modelsStack
        }
        SColumnButton {
            label: "Hypernets"
            property var index: 3
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "hypernet"
            index: 3
            stack: modelsStack
        }
        SColumnButton {
            label: "Embeddings"
            property var index: 4
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "embedding"
            index: 4
            stack: modelsStack
        }
        SColumnButton {
            label: "Wildcards"
            property var index: 5
            active: modelsStack.currentIndex == index
            onPressed: {
                modelsStack.currentIndex = index
                modelsStack.currentItem.folder = ""
            }
        }
        SubfolderList {
            mode: "wildcard"
            index: 2
            stack: modelsStack
        }
    }
    Rectangle {
        id: divider
        anchors.top: column.top
        anchors.bottom: column.bottom
        anchors.left: column.right
        width: 3
        color: COMMON.bg4
    }

    Rectangle {
        anchors.top: column.top
        anchors.bottom: column.bottom
        anchors.left: divider.right
        anchors.right: parent.right
        color: COMMON.bg00
        clip: true

        Rectangle {
            id: search
            width: parent.width
            height: 30
            color: COMMON.bg1

            property var text: searchInput.text

            Item {
                anchors.fill: parent
                anchors.bottomMargin: 2

                STextInput {
                    id: searchInput
                    anchors.fill: parent
                    color: COMMON.fg0
                    font.bold: false
                    font.pointSize: 11
                    selectByMouse: true
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    topPadding: 1

                    onAccepted: {
                        root.releaseFocus()
                    }
                }

                SText {
                    text: "Search..."
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    font.bold: false
                    font.pointSize: 11
                    leftPadding: 8
                    topPadding: 1
                    color: COMMON.fg2
                    visible: !searchInput.text && !searchInput.activeFocus
                }
            }
        
            Rectangle {
                width: parent.width
                anchors.bottom: parent.bottom
                height: 2
                color: COMMON.bg4
            }
        }
        Item {
            clip: true
            anchors.fill: parent
            anchors.topMargin: search.height

            StackLayout {
                id: modelsStack
                currentIndex: 0
                anchors.fill: parent
                property var currentItem: modelsStack.children[modelsStack.currentIndex]
                property var searchText: search.text

                ModelGrid {
                    mode: "checkpoint"
                }
                ModelGrid {
                    mode: "component"
                }
                ModelGrid {
                    mode: "lora"
                }
                ModelGrid {
                    mode: "hypernet"
                }
                ModelGrid {
                    mode: "embedding"
                }
                ModelGrid {
                    mode: "wildcard"
                }
            }
        }
    }

    Keys.onPressed: {
        var current = modelsStack.currentItem
        event.accepted = true
        if(event.modifiers & Qt.ControlModifier) {
            switch(event.key) {
            case Qt.Key_Minus:
                if(current.cellSize > 150) {
                    current.cellSize -= 100
                }
                break;
            case Qt.Key_Equal:
                if(current.cellSize < 450) {
                    current.cellSize += 100
                }
                break;
            default:
                event.accepted = false
                break;
            }
        } else {
            switch(event.key) {
            case Qt.Key_Escape:
                if(searchInput.activeFocus) {
                    search.text = ""
                    searchInput.text = ""
                    root.releaseFocus()
                }
                break;
            default:
                event.accepted = false
                break;
            }
        }
    }
}