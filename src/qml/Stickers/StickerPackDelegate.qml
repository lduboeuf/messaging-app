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
//import Qt.labs.folderlistmodel 2.2
import Ubuntu.Components 1.3
import messagingapp.private 0.1

AbstractButton {
    id: root
    //property alias path: stickers.folder
    property string fileSystemPath: ""
    //property string thumbnail: ""
    //property  int count:0
    property string name
    property bool selected
    //property var stickerPack: FileOperations.dirStat(fileSystemPath)
    height: units.gu(6)
    width: height



    Rectangle {
        height: units.gu(0.2)
        width: parent.width
        anchors.bottom: parent.bottom
        color: selected ? theme.palette.normal.selectionText  : "transparent"
    }

//    Icon {
//        anchors.fill: parent
//        anchors.margins: units.gu(0.5)
//        visible: stickerPack.count === 0
//        name: "stock_image"
//    }

    Image {
        id: image
        //visible: stickerPack.count > 0
        anchors.fill: parent
        anchors.margins: units.gu(0.5)
        sourceSize.height: parent.height
        sourceSize.width: parent.width
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        source: count> 0 ? "file://" + thumbnail : "image://theme/stock_image"
    }



//    FolderListModel {
//        id: stickers
//        showDirs: false
//        caseSensitive: false
//        nameFilters: ["*.png", "*.webm", "*.gif", "*.jpg"]
//    }

//    Component.onCompleted: {
//        console.log('path:', fileSystemPath)
//        var mStat = FileOperations.dirStat(fileSystemPath)
//        image.source = mStat.thumbnail
//        console.log(JSON.stringify(mStat))
//    }

}
