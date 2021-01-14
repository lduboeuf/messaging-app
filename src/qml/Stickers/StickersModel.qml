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
import Qt.labs.folderlistmodel 2.2

FolderListModel {
    property string packName
    folder: packName.length > 0 ? "%1/stickers/%2".arg(dataLocation).arg(packName) : ""
    showDirs: false
    caseSensitive: false
    nameFilters: ["*.png", "*.webm", "*.gif", "*.jpg"]
}
