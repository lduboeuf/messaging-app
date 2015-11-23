import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 0.1
import Ubuntu.Telephony 0.1

Item {
    id: composeBar

    property bool showContents: true
    property variant attachments: []
    property bool canSend: true
    property alias text: messageTextArea.text

    signal sendRequested(string text, var attachments)

    // internal properties
    property int _activeAttachmentIndex: -1

    function forceFocus() {
        messageTextArea.forceActiveFocus()
    }

    function reset() {
        textEntry.text = ""
        attachments.clear()
    }

    function addAttachments(transfer) {
        for (var i = 0; i < transfer.items.length; i++) {
            if (String(transfer.items[i].text).length > 0) {
                composeBar.text = String(transfer.items[i].text)
                continue
            }
            var attachment = {}
            if (!startsWith(String(transfer.items[i].url),"file://")) {
                composeBar.text = String(transfer.items[i].url)
                continue
            }
            var filePath = String(transfer.items[i].url).replace('file://', '')
            // get only the basename
            attachment["contentType"] = application.fileMimeType(filePath)
            if (startsWith(attachment["contentType"], "text/vcard") ||
                startsWith(attachment["contentType"], "text/x-vcard")) {
                attachment["name"] = "contact.vcf"
            } else {
                attachment["name"] = filePath.split('/').reverse()[0]
            }
            attachment["filePath"] = filePath
            attachments.append(attachment)
        }
    }

    function formattedTime(time) {
        var d = new Date(0, 0, 0, 0, 0, time)
        return d.getHours() == 0 ? Qt.formatTime(d, "mm:ss") : Qt.formatTime(d, "h:mm:ss")
    }

    anchors.bottom: isSearching ? parent.bottom : keyboard.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: showContents ? textEntry.height + units.gu(2) : 0
    visible: showContents
    clip: true

    Behavior on height {
        UbuntuNumberAnimation { }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            forceFocus()
        }
    }

    ListModel {
        id: attachments
    }

    Component {
        id: attachmentPopover

        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                ListItem.Standard {
                    text: i18n.tr("Remove")
                    onClicked: {
                        attachments.remove(_activeAttachmentIndex)
                        PopupUtils.close(popover)
                    }
                }
            }
            Component.onDestruction: _activeAttachmentIndex = -1
        }
    }

    ListItem.ThinDivider {
        anchors.top: parent.top
    }

    Row {
        id: leftSideActions

        width: childrenRect.width
        height: childrenRect.height

        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            verticalCenter: sendButton.verticalCenter
        }
        spacing: units.gu(2)

        PictureImport {
            id: pictureImporter

            onPictureReceived: {
                var attachment = {}
                var filePath = String(pictureUrl).replace('file://', '')
                attachment["contentType"] = application.fileMimeType(filePath)
                attachment["name"] = filePath.split('/').reverse()[0]
                attachment["filePath"] = filePath
                attachments.append(attachment)
                textEntry.forceActiveFocus()
            }
        }

        TransparentButton {
            id: attachButton
            objectName: "attachButton"
            iconName: "camera-app-symbolic"
            onClicked: {
                Qt.inputMethod.hide()
                pictureImporter.requestNewPicture()
            }
        }
    }

    StyledItem {
        id: textEntry
        property alias text: messageTextArea.text
        property alias inputMethodComposing: messageTextArea.inputMethodComposing
        property int fullSize: attachmentThumbnails.height + messageTextArea.height
        style: Theme.createStyleComponent("TextAreaStyle.qml", textEntry)
        anchors {
            topMargin: units.gu(1)
            top: parent.top
            left: leftSideActions.right
            leftMargin: units.gu(2)
            right: sendButton.left
            rightMargin: units.gu(2)
        }
        height: attachments.count !== 0 ? fullSize + units.gu(1.5) : fullSize
        onActiveFocusChanged: {
            if(activeFocus) {
                messageTextArea.forceActiveFocus()
            } else {
                focus = false
            }
        }
        focus: false
        MouseArea {
            anchors.fill: parent
            onClicked: forceFocus()
        }
        Flow {
            id: attachmentThumbnails
            spacing: units.gu(1)
            anchors{
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: units.gu(1)
                leftMargin: units.gu(1)
                rightMargin: units.gu(1)
            }
            height: childrenRect.height

            Repeater {
                model: attachments
                delegate: Loader {
                    id: loader
                    height: units.gu(8)
                    source: {
                        var contentType = getContentType(filePath)
                        console.log(contentType)
                        switch(contentType) {
                        case ContentType.Contacts:
                            return Qt.resolvedUrl("ThumbnailContact.qml")
                        case ContentType.Pictures:
                            return Qt.resolvedUrl("ThumbnailImage.qml")
                        case ContentType.Unknown:
                            return Qt.resolvedUrl("ThumbnailUnknown.qml")
                        default:
                            console.log("unknown content Type")
                        }
                    }
                    onStatusChanged: {
                        if (status == Loader.Ready) {
                            item.index = index
                            item.filePath = filePath
                        }
                    }

                    Connections {
                        target: loader.status == Loader.Ready ? loader.item : null
                        ignoreUnknownSignals: true
                        onPressAndHold: {
                            Qt.inputMethod.hide()
                            _activeAttachmentIndex = target.index
                            PopupUtils.open(attachmentPopover, parent)
                        }
                    }
                }
            }
        }

        ListItem.ThinDivider {
            id: divider

            anchors {
                left: parent.left
                right: parent.right
                top: attachmentThumbnails.bottom
                margins: units.gu(0.5)
            }
            visible: attachments.count > 0
        }

        TextArea {
            id: messageTextArea
            objectName: "messageTextArea"
            anchors {
                top: attachments.count == 0 ? textEntry.top : attachmentThumbnails.bottom
                left: parent.left
                right: parent.right
            }
            // this value is to avoid letter being cut off
            height: units.gu(4.3)
            style: LocalTextAreaStyle {}
            autoSize: true
            maximumLineCount: attachments.count == 0 ? 8 : 4
            placeholderText: {
                if (telepathyHelper.ready) {
                    var account = telepathyHelper.accountForId(presenceRequest.accountId)
                    if (account && 
                            (presenceRequest.type != PresenceRequest.PresenceTypeUnknown &&
                             presenceRequest.type != PresenceRequest.PresenceTypeUnset) &&
                             account.protocolInfo.serviceName !== "") {
                        console.log(presenceRequest.accountId)
                        console.log(presenceRequest.type)
                        return account.protocolInfo.serviceName
                    }
                }
                return i18n.tr("Write a message...")
            }
            focus: textEntry.focus
            font.family: "Ubuntu"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            color: "#5d5d5d"
        }
    }

    TransparentButton {
        id: sendButton
        objectName: "sendButton"
        anchors.verticalCenter: textEntry.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: units.gu(2)
        iconSource: Qt.resolvedUrl("./assets/send.svg")
        enabled: (canSend && (textEntry.text != "" || textEntry.inputMethodComposing || attachments.count > 0))

        onClicked: {
            // make sure we flush everything we have prepared in the OSK preedit
            Qt.inputMethod.commit();
            if (textEntry.text == "" && attachments.count == 0) {
                return
            }

            composeBar.sendRequested(textEntry.text, attachments)
        }
    }
}
