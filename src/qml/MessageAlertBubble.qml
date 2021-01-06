/*
 * Copyright 2020 Ubports Foundation.
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
import Ubuntu.Contacts 0.1
import Ubuntu.History 0.1
import QtGraphicalEffects 1.0

ListItemWithActions{

    id: root
    property var messageData: null
    property var account: null //not used but needed to avoid error in logs

    readonly property bool unknown: (messageData.textMessageStatus === HistoryThreadModel.MessageStatusUnknown)
    readonly property bool pending: (messageData.textMessageStatus === HistoryThreadModel.MessageStatusPending)
    readonly property bool temporaryError: (messageData.textMessageStatus === HistoryThreadModel.MessageStatusTemporarilyFailed)
    readonly property bool permanentError: (messageData.textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed)

    height: errorTxt.height + redownloadButton.height + textTimestamp.height + units.gu(2)
    anchors {
        topMargin: units.gu(0.5)
        bottomMargin: units.gu(0.5)
    }

    Image {
        id: image
        source: "image://theme/mail-mark-important"
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: rectangle.verticalCenter
        sourceSize.height: units.gu(4)
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
    }

    ColorOverlay {
        anchors.fill: image
        source: image
        color: "red"
    }

    Rectangle {
        id: rectangle
        anchors {
            left: image.right
            leftMargin: units.gu(1)
        }
        height: errorTxt.height + redownloadButton.height + units.gu(1)
        width: units.gu(0.5)
        color: "red"
    }

    Label {
        id: errorTxt
        text: i18n.tr("Oops, there has been an error with the MMS system and this message could not be retrieved. Please ensure Cellular Data is ON and MMS settings are correct, then ask the sender to try again.")+
              "messageData.textMessageStatus: "+messageData.textMessageStatus
        fontSize: "medium"
        anchors {
            left: rectangle.right
            leftMargin: units.gu(1)
            right: parent.right
        }
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        color: Theme.palette.normal.backgroundText
    }


    Label {
        id: textTimestamp
        objectName: "messageDate"

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        height: units.gu(2)
        fontSize: "x-small"
        color: Theme.palette.normal.backgroundText
        elide: Text.ElideRight
        text: Qt.formatTime(messageData.timestamp, Qt.DefaultLocaleShortDate)


    }

    Button {
        id: redownloadButton
        text: "Redownload"
        visible: !unknown && !permanentError
        enabled: temporaryError
        anchors.top: errorTxt.bottom
        anchors.topMargin: units.gu(1)
        anchors.left: errorTxt.left
        function logList(pref, obj) {
            for (var p in obj) {
                console.log(pref+"."+p+":" , obj[p])
            }
        }
        onClicked: function() {
            //TODO:jezek - add tests, documentation, changelog, etc...
            //TODO:jezek - figure out animations, etc...
            console.log("jezek - Redownload clicked")
            chatManager.redownloadMessage(messageData.accountId, messageData.threadId, messageData.eventId)
        }
    }


    leftSideAction: Action {
        id: deleteAction
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: eventModel.removeEvents([messageData.properties]);
    }

}
