import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.0


import gui 1.0

import "../../style"
import "../../components"

Item {
    id: root
    clip: true
    property var swap: GUI.config != null ? GUI.config.get("swap") : false
    onSwapChanged: {
        leftDivider.offset = 210
        rightDivider.offset = 210
    }

    function releaseFocus() {
        parent.releaseFocus()
    }

    SDialog {
        id: buildDialog
        title: "Build model"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        dim: true

        Connections {
            target: BASIC
            function onStartBuildModel() {
                buildDialog.open()
            }
        }

        OTextInput {
            id: filenameInput
            width: 290
            height: 30
            label: "Filename"
            value: GUI.modelName(BASIC.parameters.values.get("UNET")) + ".safetensors"
        }

        width: 300
        height: 87

        onAccepted: {
            BASIC.buildModel(filenameInput.value)
        }
    }

    AdvancedDropArea {
        id: basicDrop
        anchors.fill: parent

        onDropped: {
            BASIC.pasteDrop(mimeData)
        }
    }

    Item {
        id: leftArea
        anchors.left: parent.left
        anchors.right: divider.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    SDividerVR {
        id: rightDivider
        visible: !root.swap
        minOffset: 5
        maxOffset: 300
        offset: 210

        onLimitedChanged: {
            if(limited) {
                BASIC.dividerDrag()
            }
        }
    }

    SDividerVL {
        id: leftDivider
        visible: root.swap
        minOffset: 0
        maxOffset: 300
        offset: 210

        onLimitedChanged: {
            if(limited) {
                BASIC.dividerDrag()
            }
        }
    }
    
    Item {
        id: rightArea
        anchors.left: divider.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

    property var divider: root.swap ? leftDivider : rightDivider
    property var mainArea: root.swap ? rightArea : leftArea
    property var settingsArea: root.swap ? leftArea : rightArea

    BasicAreas {
        id: areas
        clip: true
        anchors.left: mainArea.left
        anchors.top: mainArea.top
        anchors.right: mainArea.right
        anchors.bottom: promptDivider.top
    }

    BasicFull {
        id: full
        anchors.fill: areas

        onContextMenu: {
            if(BASIC.openedArea == "output" && full.target.ready) {
                fullContextMenu.popup()
            }
        }

        SContextMenu {
            id: fullContextMenu

            SContextMenuItem {
                text: "Show Parameters"
                checkable: true
                checked: fullParams.show
                onCheckedChanged: {
                    if(checked != fullParams.show) {
                        fullParams.show = checked
                        checked = Qt.binding(function() { return fullParams.show })
                    }
                }
            }

            property var output: full.target != null && full.target.file != ""

            SContextMenuSeparator {
                visible: fullContextMenu.output
            }

            SContextMenuItem {
                id: outputContext
                visible: fullContextMenu.output
                text: "Open"
                onTriggered: {
                    GALLERY.doOpenImage([full.file])
                }
            }

            SContextMenuItem {
                text: "Visit"
                visible: fullContextMenu.output
                onTriggered: {
                    GALLERY.doOpenFolder([full.file])
                }
            }

            SContextMenuSeparator {
                visible: fullContextMenu.output
            }

            Sql {
                id: destinationsSql
                query: "SELECT name, folder FROM folders WHERE UPPER(name) != UPPER('" + full.file + "');"
            }

            SContextMenu {
                id: fullCopyToMenu
                title: "Copy to"
                Instantiator {
                    model: destinationsSql
                    SContextMenuItem {
                        visible: fullContextMenu.output
                        text: sql_name
                        onTriggered: {
                            GALLERY.doCopy(sql_folder, [full.file])
                        }
                    }
                    onObjectAdded: fullCopyToMenu.insertItem(index, object)
                    onObjectRemoved: fullCopyToMenu.removeItem(object)
                }
            }
        }
    }

    Rectangle {
        id: settings
        color: COMMON.bg0
        anchors.left: settingsArea.left
        anchors.right: settingsArea.right
        anchors.top: settingsArea.top
        anchors.bottom: statusDivider.top

        Parameters {
            id: params
            anchors.fill: parent
            binding: BASIC.parameters
            swap: root.swap

            remaining: BASIC.remaining

            onGenerate: {
                BASIC.generate()
            }
            onCancel: {
                BASIC.cancel()
            }
            onForeverChanged: {
                BASIC.forever = params.forever
            }
            onBuildModel: {
                BASIC.doBuildModel()
            }
            function sizeDrop(mimeData) {
                BASIC.sizeDrop(mimeData)
            }
            function seedDrop(mimeData) {
                BASIC.seedDrop(mimeData)
            }
        }
    }

    SDividerHB {
        id: statusDivider
        anchors.left: settingsArea.left
        anchors.right: settingsArea.right
        minOffset: 50
        maxOffset: 70
        offset: 50
    }

    Status {
        anchors.top: statusDivider.bottom
        anchors.bottom: settingsArea.bottom
        anchors.left: settingsArea.left
        anchors.right: settingsArea.right
    }

    SDividerHB {
        id: promptDivider
        anchors.left: mainArea.left
        anchors.right: mainArea.right
        minOffset: 5
        maxOffset: 300
        offset: 150
    }

    Prompts {
        id: prompts
        anchors.left: mainArea.left
        anchors.right: mainArea.right
        anchors.bottom: mainArea.bottom
        anchors.top: promptDivider.bottom

        bindMap: BASIC.parameters.values

        Component.onCompleted: {
            GUI.setHighlighting(positivePromptArea.area.textDocument)
            GUI.setHighlighting(negativePromptArea.area.textDocument)
        }

        onPositivePromptChanged: {
            BASIC.parameters.promptsChanged()
        }
        onNegativePromptChanged: {
            BASIC.parameters.promptsChanged()
        }
        onInspect: {
            BASIC.pasteText(positivePrompt)
        }
        onTab: {
            if(suggestions.visible) {
                suggestions.complete()
            } else {
                root.forceActiveFocus()
                prompts.inactive.forceActiveFocus()
            }
        }
        onMenu: {
            if(suggestions.visible) {
                if(dir == 0) {
                    promptCursor.typed = false
                } else if (dir == 1) {
                    suggestions.incrementCurrentIndex()
                    suggestions.positionViewAtIndex(suggestions.currentIndex, ListView.Contain)
                } else if (dir == -1) {
                    suggestions.decrementCurrentIndex()
                    suggestions.positionViewAtIndex(suggestions.currentIndex, ListView.Contain)
                }
            }
        }
    }

    Item {
        id: promptCursor
        visible: typed && prompts.cursorX != null && prompts.cursorText != ""
        x: visible ? prompts.x + prompts.cursorX : 0
        y: visible ? prompts.y + prompts.cursorY - height - 2 : 0
        width: 200
        height: 1

        property var typed: false
        property var targetStart: null
        property var targetEnd: null

        Connections {
            target: prompts

            function onInput() {
                promptCursor.typed = true
            }

            function onCursorTextChanged() {
                if(prompts.cursorText == null) {
                    promptCursor.typed = false
                } else if (promptCursor.typed) {
                    BASIC.updateSuggestions(prompts.cursorText, prompts.cursorPosition)
                    promptCursor.targetStart = BASIC.suggestionStart(prompts.cursorText, prompts.cursorPosition)
                    promptCursor.targetEnd = BASIC.suggestionEnd(prompts.cursorText, prompts.cursorPosition)
                }
            }
        }
    }

    Rectangle {
        visible: suggestions.visible
        anchors.fill: suggestions
        color: COMMON.bg2
        border.width: 1
        border.color: COMMON.bg4
        anchors.margins: -1
    }
    Rectangle {
        visible: suggestions.visible
        anchors.fill: suggestions
        color: "transparent"
        border.width: 1
        border.color: COMMON.bg0
        anchors.margins: -2
    }

    ListView {
        id: suggestions
        visible: promptCursor.visible && BASIC.suggestions.length != 0
        anchors.left: promptCursor.left
        anchors.right: promptCursor.right
        anchors.bottom: promptCursor.bottom
        height: Math.min(contentHeight, 3*20)
        clip: true
        model: BASIC.suggestions

        verticalLayoutDirection: ListView.BottomToTop
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false

        function complete() {
            var curr = prompts.active
            curr.completeText(suggestions.currentItem.text, promptCursor.targetStart, promptCursor.targetEnd)
        }

        ScrollBar.vertical: SScrollBarV {
            id: suggestionsScrollBar
            padding: 0
            barWidth: 2
            stepSize: 1/(BASIC.suggestions.length)
            policy: suggestions.contentHeight > suggestions.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        delegate: Rectangle {
            width: suggestions.width
            height: 20
            property var selected: suggestions.currentIndex == index
            property var text: BASIC.suggestionDisplay(modelData)
            color: selected ?  COMMON.bg4 : COMMON.bg3

            SText {
                id: decoText
                anchors.right: parent.right
                width: contentWidth
                height: 20
                text: BASIC.suggestionDetail(modelData)
                color: width < contentWidth ? "transparent" : COMMON.fg2
                font.pointSize: 8.5
                rightPadding: 8
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
            SText {
                id: valueText
                anchors.left: parent.left
                anchors.right: decoText.left

                height: 20
                text: parent.text
                color: BASIC.suggestionColor(modelData)
                font.pointSize: 8.5
                leftPadding: 5
                rightPadding: 10
                elide: Text.ElideRight

                verticalAlignment: Text.AlignVCenter
            }
            MouseArea {
                id: delegateMouse
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                onPressed: {
                    suggestions.complete()
                }
                onEntered: {
                    suggestions.currentIndex = index
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: {
                if(wheel.angleDelta.y < 0) {
                    suggestionsScrollBar.increase()
                } else {
                    suggestionsScrollBar.decrease()
                }
            }
        }
    }

    Rectangle {
        id: fullParams
        anchors.fill: prompts
        visible: full.visible && parameters != "" && show
        color: COMMON.bg0
        property var parameters: full.target != null ? (full.target.parameters != undefined ? full.target.parameters : "") : ""
        property var show: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            border.width: 1
            border.color: COMMON.bg4
            color: "transparent"

            Rectangle {
                id: headerParams
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 25
                border.width: 1
                border.color: COMMON.bg4
                color: COMMON.bg3
                SText {
                    anchors.fill: parent
                    text: "Parameters"
                    color: COMMON.fg1_5
                    leftPadding: 5
                    verticalAlignment: Text.AlignVCenter
                }

                SIconButton {
                    visible: fullParams.visible
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 23
                    width: 23
                    tooltip: "Hide Parameters"
                    icon: "qrc:/icons/eye.svg"
                    onPressed: {
                        fullParams.show = false
                    }
                }
            }

            STextArea {
                color: COMMON.bg1
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerParams.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 1

                readOnly: true

                text: fullParams.parameters

                Component.onCompleted: {
                    GUI.setHighlighting(area.textDocument)
                }
            }
        }
    }

    AdvancedDropArea {
        id: leftDrop
        visible: !root.swap
        width: 10
        height: parent.height
        anchors.left: leftArea.left
        anchors.top: leftArea.top
        anchors.bottom: leftArea.bottom
        filters: ['application/x-qd-basic-divider']

        onDropped: {
            if(BASIC.dividerDrop(mimeData)) {
                root.swap = !root.swap
            }
        }

        Rectangle {
            visible: leftDrop.containsDrag
            width: 3
            color: COMMON.bg6
            height: parent.height
        }
    }

    AdvancedDropArea {
        id: rightDrop
        visible: root.swap
        width: 10
        height: parent.height
        anchors.right: rightArea.right
        anchors.top: rightArea.top
        anchors.bottom: rightArea.bottom
        filters: ['application/x-qd-basic-divider']

        onDropped: {
            BASIC.dividerDrop(mimeData)
        }

        Rectangle {
            visible: rightDrop.containsDrag
            anchors.right: parent.right
            width: 3
            color: COMMON.bg6
            height: parent.height
        }
    }

    Shortcut {
        sequences: COMMON.keys_generate
        onActivated: BASIC.generate()
    }
    Shortcut {
        sequences: COMMON.keys_cancel
        onActivated: BASIC.cancel()
    }

    Keys.onPressed: {
        event.accepted = true
        if(event.modifiers & Qt.ControlModifier) {
            switch(event.key) {
            case Qt.Key_V:
                BASIC.pasteClipboard()
                break;
            default:
                event.accepted = false
                break;
            }
        } else {
            switch(event.key) {
            default:
                event.accepted = false
                break;
            }
        }
    }

    ImportDialog  {
        id: importDialog
        title: "Import"
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        dim: true

        onAccepted: {
            BASIC.parameters.sync(importDialog.parser.parameters)
        }

        onClosed: {
            importDialog.parser.formatted = ""
        }

        Connections {
            target: BASIC
            function onPastedText(text) {
                importDialog.parser.formatted = text
            }
        }
    }

    Keys.forwardTo: [areas, full]
}