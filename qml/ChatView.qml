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

            // System messages are API instructions only and are never rendered.
            // The typing indicator uses a smaller fixed-size bubble.
            height: role === "user" || role === "assistant" || role === "error" ? bubble.height
                  : role === "typing" ? typingBubble.height
                  : 0

            Rectangle {
                id: bubble
                visible: messageDelegate.role === "user"
                         || messageDelegate.role === "assistant"
                         || messageDelegate.role === "error"

                property bool isMe: messageDelegate.role === "user"

                width: Math.min(
                           messageText.implicitWidth + dp(24),
                           messageDelegate.width * 0.75)
                height: messageText.implicitHeight + dp(20)

                radius: dp(14)

                // User messages are blue, assistant messages green and error
                // messages red, so problems are instantly recognizable.
                color: isMe ? "#2878f0"
                      : messageDelegate.role === "error" ? "#c62828"
                      : "#1f8b03"

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

            // Shown while we wait for the API response. It is removed and
            // replaced with the actual message as soon as the answer arrives.
            Rectangle {
                id: typingBubble
                visible: messageDelegate.role === "typing"

                width: dp(76)
                height: dp(40)

                radius: dp(14)
                color: "#1f8b03"

                anchors.left: parent.left

                Row {
                    anchors.centerIn: parent
                    spacing: dp(6)

                    Repeater {
                        model: 3

                        Rectangle {
                            property real baseOpacity: 0.3

                            width: dp(8)
                            height: dp(8)
                            radius: dp(4)
                            color: "white"
                            opacity: baseOpacity

                            // Each dot blinks in turn, the pause before the
                            // animation is staggered by the dot index.
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite

                                PauseAnimation { duration: index * 200 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 250 }
                                NumberAnimation { from: 1.0; to: 0.3; duration: 250 }
                                PauseAnimation { duration: 700 }
                            }
                        }
                    }
                }
            }
        }
    }

    function scrollToBottom() {
        chatView.positionViewAtEnd()
    }
}
