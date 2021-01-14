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
    property string currrentStickerPackPath: ""

    // FIXME: try to get something similar to the keyboard height
    // FIXME: animate the displaying
    //height: expanded ? units.gu(30) : 0
    height: units.gu(30)
    //opacity: expanded ? 1 : 0
    //visible: opacity > 0

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.foreground
    }

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (Qt.inputMethod.visible) {
                pickerRoot.expanded = false
            }
        }
    }

    Behavior on height {
        UbuntuNumberAnimation { }
    }

    Behavior on opacity {
        UbuntuNumberAnimation { }
    }

    ContentImport {
        id: contentImporter

        onContentReceived: {
            var attachment = {}
            var filePath = String(contentUrl).replace('file://', '')
            var fileName = filePath.split('/').reverse()[0]
            var destFile =  "%1/%2".arg(currrentStickerPackPath.replace('file://', '')).arg(fileName)
            FileOperations.copyFile(filePath, destFile);
        }
    }

    Component {
        id: stickerPopover

        Popover {
            id: popover
            property string toRemove: ""

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
                    onClicked: {
                        FileOperations.remove(popover.toRemove.replace('file://', ''))
                        PopupUtils.close(popover)
                    }
                }

            }
        }
    }

    Component {
        id: confirmDeleteComponent
        Dialog {
            id: dialog
            property string toRemove: ""

            title: i18n.tr("Stickers")
            text: i18n.tr("Please confirm that you want to delete all stickers in this pack")

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
                    onClicked: {
                        FileOperations.removeDir(dialog.toRemove.replace('file://', ''))
                        stickersGrid.model.packName = ""
                        PopupUtils.close(dialog)
                    }
                }
            }
        }
    }


    StickerPacksModel {
        id: stickerPacksModel
    }

    StickersModel {
        id: stickersModel
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

            onTriggered: stickersGrid.model.packName = ""
            selected: stickersGrid.model.packName === ""
        }
        delegate: StickerPackDelegate {
            height: units.gu(6)
            width: height

            path: filePath
            onClicked: stickersGrid.model.packName = fileName
            selected: stickersGrid.model.packName === fileName
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
            //backend need filepath without "file://" if any
            newFolder = String(newFolder).replace('file://', '')
            FileOperations.create(newFolder)
            stickersGrid.model.packName = packName
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
        visible: stickersGrid.model.packName.length > 0

        model: stickersModel

        delegate: StickerDelegate {
            id:sticker
            stickerSource: filePath
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onClicked: {
                StickersHistoryModel.add("%1/%2".arg(stickersGrid.model.packName).arg(fileName))
                pickerRoot.stickerSelected(stickerSource)
            }

            onPressAndHold: {
                currrentStickerPackPath = stickerSource
                PopupUtils.open(stickerPopover, sticker, { 'toRemove': stickerSource })
            }

        }
    }

    Row {
        anchors.bottom: stickersGrid.bottom
        anchors.right: stickersGrid.right
        visible: stickersGrid.model.packName.length > 0
        StickerDelegate {
            stickerSource: "image://theme/import"
            height: units.gu(6)
            width: height
            anchors.margins: units.gu(1.5)

            onTriggered: {
                currrentStickerPackPath = "%1/%2".arg(stickerPacksModel.folder).arg(stickersGrid.model.packName)
                contentImporter.requestPicture()
            }
        }
        StickerDelegate {
            stickerSource: "image://theme/edit-delete"
            height: units.gu(6)
            width: height
            anchors.margins: units.gu(1.5)

            onTriggered: {
                PopupUtils.open(confirmDeleteComponent, null, { 'toRemove':   "%1/%2".arg(stickerPacksModel.folder).arg(stickersGrid.model.packName)})
            }
        }
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
        visible: stickersGrid.model.packName.length === 0

        model: StickersHistoryModel

        delegate: StickerDelegate {
            stickerSource: "%1/stickers/%2".arg(dataLocation).arg(sticker)
            width: stickersGrid.cellWidth
            height: stickersGrid.cellHeight

            onTriggered: {
                StickersHistoryModel.add(sticker)
                pickerRoot.stickerSelected(stickerSource)
            }
        }
    }
}
