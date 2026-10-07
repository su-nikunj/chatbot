import Felgo
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

App {
    NavigationStack {

        AppPage {
            title: qsTr("Chat")

            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                }

                spacing: 8

                AppTextField {
                    id: inputMessage
                    placeholderText: "Send a message"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45

                    onAccepted: {
                        console.log("Enter pressed")
                    }
                }

                Button {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 45
                    text: "➡️"
                    onClicked: {
                        console.log("Pressed")
                    }
                }
            }
        }

    }
}
