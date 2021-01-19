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

import QtQuick 2.3
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Qt.labs.folderlistmodel 2.2
import messagingapp.private 0.1

import ".." //ContentImport

FocusScope {
    id: pickerRoot

    signal stickerSelected(string path)

    Component.onCompleted: {
        StickersHistoryModel.databasePath = dataLocation + "/stickers/stickers.sqlite"
        StickersHistoryModel.limit = 10
    }

    property bool expanded: false
    readonly property int packCount: stickerPacksModel.count
    property string currentStickerPackPath: ""

    height: units.gu(30)

    //backend need filepath without "file://" if any
    function toSystemPath(path) {
        return path.replace('file://', '')
    }

    function removePack(packPath) {
        FileOperations.removeDir(toSystemPath(packPath))
        //TODO remove from history ( use signal / slots in c++ )
        stickersModel.packName = ""
    }

    function removeSticker(path) {
        var filePath = toSystemPath(path)
        FileOperations.remove(filePath)
        StickersHistoryModel.remove(filePath)
    }

    function importStickerRequested(currentPackPath) {
        currentStickerPackPath = currentPackPath
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
            property string toRemove: ""

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
        model: stickerPacksModel
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

            path: filePath
            onClicked: stickersModel.packName = fileName
            selected: stickersModel.packName === fileName
        }


    }


    AbstractButton {
        anchors.bottom: setsList.bottom
        anchors.right: setsList.right
        height: units.gu(6)
        width: height

        Icon {
            name: "add"
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
        }

        onTriggered:  {
            //create a random packName
            var packName = Math.random().toString(36).substr(2, 5)
            var newFolder = stickerPacksModel.folder + packName
            newFolder = toSystemPath(String(newFolder))
            FileOperations.create(newFolder)
            stickersModel.packName = packName
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
            id:sticker
            stickerSource: filePath
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onClicked: {
                StickersHistoryModel.add(filePath)
                pickerRoot.stickerSelected(filePath)
            }

            onPressAndHold: {
                var dialog = PopupUtils.open(stickerPopover, sticker)
                dialog.accepted.connect(function() {
                    removeSticker(filePath)
                })
            }

        }

    }

    Label {
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
            stickerSource: "%1/stickers/%2".arg(dataLocation).arg(sticker)
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onClicked: {
                StickersHistoryModel.add(sticker)
                pickerRoot.stickerSelected(stickerSource)
            }
        }
    }

    Row {
        anchors.bottom: stickersGrid.bottom
        anchors.right: stickersGrid.right
        StickerDelegate {
            stickerSource: "image://theme/import"
            height: units.gu(6)
            width: height
            anchors.margins: units.gu(1.5)
            visible: stickersModel.packName.length > 0
            onTriggered: {
                pickerRoot.importStickerRequested("%1/%2".arg(stickerPacksModel.folder).arg(stickersModel.packName))
            }
        }
        StickerDelegate {
            stickerSource: "image://theme/edit-delete"
            height: units.gu(6)
            width: height
            anchors.margins: units.gu(1.5)

            onTriggered: {
                if (stickersModel.packName.length > 0) {
                    var path =  "%1/%2".arg(stickerPacksModel.folder).arg(stickersModel.packName)
                    var dialog = PopupUtils.open(confirmDeleteComponent, null)
                    dialog.accepted.connect(function() {
                        removePack(path)
                    })
                } else {
                    StickersHistoryModel.clearAll()
                }

            }
        }
    }


}
