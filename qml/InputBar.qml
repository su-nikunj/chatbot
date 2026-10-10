import Felgo
import QtQuick

// The message input row: a text field with a send button
Row {
    id: root

    // While busy, the input is disabled so no second message can be sent
    // before the API answered the first one.
    property bool busy: false

    signal sendRequested(string message)

    spacing: dp(8)
    height: dp(45)

    function submit() {
        sendRequested(inputMessage.text.trim())
        inputMessage.text = ""
    }

    AppTextField {
        id: inputMessage
        placeholderText: "Send a message"
        width: root.width - sendButton.width - root.spacing
        height: dp(45)
        enabled: !root.busy

        onAccepted: root.submit()
    }

    AppButton {
        id: sendButton

        width: dp(100)
        height: dp(45)
        text: root.busy ? "..." : "➡️"
        enabled: !root.busy

        onClicked: root.submit()
    }
}
