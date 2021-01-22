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
import Qt.labs.folderlistmodel 2.12
import messagingapp.private 0.1

Item {
    id: root
    property string packPath: dataLocation + "/stickers/"
    property alias model : stickerPackExtendedModel

    signal packSelected(string packName)

    function toSystemPath(path) {
        return path.replace('file://', '')
    }

    function createPack() {
        console.trace()
        //create a random packName
        var packName = Math.random().toString(36).substr(2, 5)
        var newFolder = stickerPacksModel.folder + packName
        newFolder = toSystemPath(String(newFolder))
        FileOperations.create(newFolder)
    }

    function removePack(packName) {
        var path =  "%1/%2".arg(packPath).arg(packName)
        FileOperations.removeDir(toSystemPath(path))
    }


    // according to FolderListModel, build a model with the count of each pack and a default thumbnail
    function loadModel() {
        stickerPackExtendedModel.clear()
        var fPath, hasEmptyPack = false
        for (var i=0; i < stickerPacksModel.count; i++) {
            fPath = stickerPacksModel.get(i, 'filePath')
            var dirStat = FileOperations.dirStat(toSystemPath(fPath))
            dirStat.packName = stickerPacksModel.get(i, 'fileName')
            if (dirStat.count === 0 ) hasEmptyPack = true
            stickerPackExtendedModel.append(dirStat)
        }

        if (!hasEmptyPack) {
            createPack()
        }
    }

    function checkForUpdate(index, expectedCount, packName) {

        //no update when no packName
        if (packName.length === 0) return

        var pack = stickerPackExtendedModel.get(index)
        var currentCount = pack.count
        if (currentCount !== expectedCount) {
            // no more stickers in there, we can remove the pack
            if (expectedCount === 0) {
                removePack(pack.packName)
            } else {
                // update model
                var filePath = stickerPacksModel.get(index, 'filePath')
                var dirStat = FileOperations.dirStat(toSystemPath(filePath))
                dirStat.packName = pack.packName
                stickerPackExtendedModel.set(index, dirStat)

                if (currentCount === 0) {
                    createPack()
                }

            }

        }
    }


    ListModel {
        id: stickerPackExtendedModel
    }


    FolderListModel {
        id: stickerPacksModel
        folder: root.packPath
        showFiles: false
        sortField: FolderListModel.Time
        sortReversed: true



        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                // create at least one pack
                if (count === 0) {
                    createPack()
                }
            }
        }
        onCountChanged: loadModel()

    }



}


