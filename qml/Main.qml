import Felgo
import QtQuick

App {
    id: app

    ListModel {
        id: chatMessages

        ListElement {
            role: "system"
            content: `
            You are a friendly chat assistant that mimicks a human chat experience.
            A human does not send multiple paragraphs of text as response, only 1 or 2 sentences in simple english.
            Also they do not use most of special characters unless absolutely necessary.`
        }
    }

    function listModelToArray(model) {
        let result = []

        for (let i = 0; i < model.count; i++) {
            result.push(model.get(i))
        }

        return result
    }

    function sendMessage(message) {
        if (message.trim() === "")
            return

        const apiUrl = app.settings.getValue(settingsDialog.apiUrl)
        const apiKey = app.settings.getValue(settingsDialog.apiKey)
        const apiModel = app.settings.getValue(settingsDialog.apiModel)

        if (!apiUrl || !apiKey || !apiModel) {
            settingsDialog.open()
            return
        }

        chatMessages.append({
                        role: "user",
                        content: message
                      })
        chatView.scrollToBottom()

        let chatUrl = apiUrl.replace(/\/+$/, "") + "/chat/completions"

        HttpRequest
            .post(chatUrl)
            .set("Content-Type", "application/json")
            .set("Authorization", `Bearer ${apiKey}`)
            .send({
                      model: apiModel,
                      messages: listModelToArray(chatMessages),
                      temperature: 0.7
                  })
            .then(res => {
                      chatMessages.append({
                                            role: "assistant",
                                            content: res.body.choices[0].message.content
                                           })
                      chatView.scrollToBottom()
                  })
            .catch(err => {
                      console.error(err)
                   })
    }

    NavigationStack {

        AppPage {
            title: qsTr("Chatbot")

            rightBarItem: IconButtonBarItem {
                iconType: IconType.cog
                title: "Settings"

                onClicked: settingsDialog.open()
            }

            leftBarItem: IconButtonBarItem {
                iconType: IconType.trash
                title: "Debug clear"

                onClicked: {
                    app.settings.clearValue(settingsDialog.apiUrl)
                    app.settings.clearValue(settingsDialog.apiKey)
                    app.settings.clearValue(settingsDialog.apiModel)
                }
            }

            SettingsDialog {
                id: settingsDialog
                settingsStore: app.settings
            }

            ChatView {
                id: chatView
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: messageRow.top
                    margins: dp(20)
                }

                messages: chatMessages
            }

            Row {
                id: messageRow

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: dp(20)
                }

                spacing: dp(8)
                height: dp(45)

                AppTextField {
                    id: inputMessage
                    placeholderText: "Send a message"
                    width: messageRow.width - sendButton.width - messageRow.spacing
                    height: dp(45)

                    onAccepted: {
                        sendMessage(inputMessage.text.trim())
                        inputMessage.text = ""
                    }
                }

                AppButton {
                    id: sendButton

                    width: dp(100)
                    height: dp(45)
                    text: "➡️"
                    onClicked: {
                        sendMessage(inputMessage.text.trim())
                        inputMessage.text = ""
                    }
                }
            }
        }

    }
}
