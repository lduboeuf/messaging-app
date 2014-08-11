/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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

import QtQuick 2.2
import Ubuntu.Components 1.1
import ".."

MMSBase {
    id: defaultDelegate

    anchors.left: parent.left
    anchors.right: parent.right
    height: bubble.height + units.gu(1)
    Item {
        id: bubble
        anchors.top: parent.top
        width: label.width + units.gu(4)
        height: label.height + units.gu(2)

        Label {
            id: label
            text: attachment.attachmentId
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: incoming ? units.gu(0.5) : -units.gu(0.5)
            fontSize: "medium"
            height: paintedHeight
            color: textColor
            opacity: incoming ? 1 : 0.9
        }
    }
}
