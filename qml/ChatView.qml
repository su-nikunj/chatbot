import Felgo
import QtQuick

Item {
    required property var messages

    AppListView {
        id: chatView
        anchors.fill: parent
        clip: true
        spacing: dp(8)

        model: messages

        delegate: Item {
            id: messageDelegate

            required property string role
            required property string content

            width: chatView.width
            height: role === "user" || role === "assistant" ? bubble.height : 0

            Rectangle {
                id: bubble
                visible: messageDelegate.role === "user"
                         || messageDelegate.role === "assistant"

                property bool isMe: messageDelegate.role === "user"

                width: Math.min(
                           messageText.implicitWidth + dp(24),
                           messageDelegate.width * 0.75)
                height: messageText.implicitHeight + dp(20)

                radius: dp(14)
                color: isMe ? "#2878f0" : "#1f8b03"

                anchors.right: isMe ? parent.right : undefined
                anchors.left: isMe ? undefined : parent.left

                AppText {
                    id: messageText

                    anchors.fill: parent
                    anchors.margins: dp(12)

                    text: messageDelegate.content
                    color: "white"

                    wrapMode: Text.Wrap
                    font.pixelSize: sp(15)
                }
            }
        }
    }

    function scrollToBottom() {
        chatView.positionViewAtEnd()
    }
}
