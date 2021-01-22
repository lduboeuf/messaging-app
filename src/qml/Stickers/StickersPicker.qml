/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Qt.labs.folderlistmodel 2.12
import messagingapp.private 0.1

import ".." //ContentImport

FocusScope {
    id: pickerRoot

    signal stickerSelected(string path)

    property bool expanded: false
    readonly property int packCount: stickerPacksModel.count
    property string currentStickerPackPath: ""

    height: units.gu(30)

    Component.onCompleted: {
        StickersHistoryModel.databasePath = dataLocation + "/stickers/stickers.sqlite"
        StickersHistoryModel.limit = 10
    }

    onStickerSelected:  {
        StickersHistoryModel.add(toSystemPath(path))
    }

    //backend need filepath without "file://" if any
    function toSystemPath(path) {
        return path.replace('file://', '')
    }

    function removeSticker(path) {
        var filePath = toSystemPath(path)
        FileOperations.remove(filePath)
        StickersHistoryModel.remove(filePath)
    }

    function importStickerRequested(packName) {
        currentStickerPackPath = "%1/%2".arg(stickerPacksModel.packPath).arg(packName)
        contentImporter.requestPicture()
        contentImporter.contentReceived.connect(importSticker)
    }

    function importSticker(contentUrl) {
        var attachment = {}
        var filePath = toSystemPath(String(contentUrl))
        var fileName = filePath.split('/').reverse()[0]
        var destFile =  "%1/%2".arg(toSystemPath(currentStickerPackPath)).arg(fileName)
        FileOperations.copyFile(filePath, destFile);
    }


    StickerPacksModel {
        id: stickerPacksModel
    }


    StickersModel {
        id: stickersModel
        onCountChanged: {
            stickerPacksModel.checkForUpdate(setsList.currentIndex, count, stickersModel.packName)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.foreground
    }


    Behavior on height {
        UbuntuNumberAnimation { }
    }

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    ContentImport {
        id: contentImporter
    }

    Component {
        id: stickerPopover

        Popover {
            id: popover

            signal accepted()
            onAccepted: PopupUtils.close(popover)

            function show() {
                visible = true;
                __foreground.show();
            }

            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }

                ListItem {
                    ListItemLayout {
                        id: layout
                        title.text: i18n.tr("Remove")
                    }
                    onClicked: accepted()
                }

            }
        }
    }

    Component {
        id: confirmDeleteComponent
        Dialog {
            id: dialog

            title: i18n.tr("Stickers")
            text: i18n.tr("Please confirm that you want to delete all stickers in this pack")

            signal accepted()

            onAccepted: PopupUtils.close(dialog)

            Row {
                id: row
                width: parent.width
                spacing: units.gu(1)
                Button {
                    width: parent.width/2 - row.spacing/2
                    text: "Cancel"
                    onClicked: PopupUtils.close(dialog)
                }
                Button {
                    width: parent.width/2 - row.spacing/2
                    text: "Confirm"
                    color: UbuntuColors.green
                    onClicked: accepted()
                }
            }
        }
    }

    ListView {
        id: setsList
        model: stickerPacksModel.model
        orientation: ListView.Horizontal
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: units.gu(6)

        header: HistoryButton {
            height: units.gu(6)
            width: height

            onTriggered: stickersModel.packName = ""
            selected: stickersModel.packName === ""
        }
        delegate: StickerPackDelegate {
            height: units.gu(6)
            width: height

            onClicked: {
                setsList.currentIndex = index
                stickersModel.packName = packName
            }
            selected: stickersModel.packName === packName
        }
    }

    GridView {
        id: stickersGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: setsList.bottom
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: units.gu(10)
        cellHeight: units.gu(10)
        visible: stickersModel.packName.length > 0

        model: stickersModel

        delegate: StickerDelegate {
            id:sticker_delegate
            stickerSource: filePath
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onClicked: {
                pickerRoot.stickerSelected(filePath)
            }

            onPressAndHold: {
                var dialog = PopupUtils.open(stickerPopover, sticker_delegate)
                dialog.accepted.connect(function() {
                    removeSticker(filePath)
                })
            }

        }

    }

    Label {
        id: no_stickers_lbl
        anchors.centerIn: stickersGrid
        visible: stickersGrid.model.packName.length > 0 && stickersGrid.model.count === 0
        text: i18n.tr("no stickers yet")
    }


    GridView {
        id: historyGrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: setsList.bottom
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: units.gu(10)
        cellHeight: units.gu(10)
        visible: stickersModel.packName.length === 0

        model: StickersHistoryModel
        delegate: StickerDelegate {
            id: history_delegate
            stickerSource: sticker
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onNotFound: {
                StickersHistoryModel.remove(sticker)
            }

            onClicked: {
                pickerRoot.stickerSelected(sticker)
            }

            onPressAndHold: {
                var dialog = PopupUtils.open(stickerPopover, history_delegate)
                dialog.accepted.connect(function() {
                    StickersHistoryModel.remove(sticker)
                })
            }
        }
    }

    Label {
        anchors.centerIn: historyGrid
        visible: StickersHistoryModel.count === 0 && stickersGrid.model.packName.length === 0
        text: i18n.tr("sent stickers will appear here")
    }

    Row {
        id: stickerActions
        padding: units.gu(0.5)
        spacing: units.gu(1)
        height: units.gu(6)
        anchors.bottom: stickersGrid.bottom
        anchors.right: stickersGrid.right

        StickerDelegate {
            stickerSource: "image://theme/import"
            height: units.gu(6)
            width: height
            visible: stickersModel.packName.length > 0
            onTriggered: {
                pickerRoot.importStickerRequested(stickersModel.packName)
            }
        }
        StickerDelegate {
            stickerSource: "image://theme/edit-delete"
            height: units.gu(6)
            width: height
            visible: (stickersModel.packName.length > 0 && stickerPacksModel.model.count > 1) || (StickersHistoryModel.count > 0 && stickersModel.packName.length === 0)

            onTriggered: {
                if (stickersModel.packName.length > 0) {
                    var dialog = PopupUtils.open(confirmDeleteComponent, null)
                    dialog.accepted.connect(function() {
                        stickerPacksModel.removePack(stickersModel.packName)
                        stickersModel.packName = ""
                    })
                } else {
                    StickersHistoryModel.clearAll()
                }

            }
        }


    }

    states: [
        State {
            name: "noStickers"
            when: stickersModel.count === 0 && stickersModel.packName.length > 0

            AnchorChanges {
                target: stickerActions
                anchors.top: no_stickers_lbl.bottom
                anchors.bottom: undefined
                anchors.left: undefined
                anchors.right: undefined
                anchors.horizontalCenter: stickersGrid.horizontalCenter
            }
        }
    ]

}
