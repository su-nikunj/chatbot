import Felgo
import QtQuick

App {
    id: app

    // The system prompt is the instruction for the model. Keep it separate from
    // the chat history, so it is not accidentally edited or removed by the user.
    readonly property string systemPrompt: `
        You are a friendly chat assistant that mimicks a human chat experience.
        A human does not send multiple paragraphs of text as response, only 1 or 2 sentences in simple english.
        Also they do not use most of special characters unless absolutely necessary.`

    // The key for chatHistory field to save
    readonly property string chatHistoryKey: "chatHistory"

    // True while we wait for the API to answer. Prevents sending multiple
    // messages at once and disables the input fields.
    property bool busy: false

    ListModel {
        id: chatMessages
    }

    // Restore the previous conversation when the app starts.
    // The system prompt is added first, so it is always the first message
    // sent to the API. Saved messages are appended after it.
    Component.onCompleted: {
        chatMessages.append({ role: "system", content: systemPrompt })

        const saved = app.settings.getValue(chatHistoryKey)

        if (saved) {
            try {
                const history = JSON.parse(saved)
                if (Array.isArray(history)) {
                    for (let i = 0; i < history.length; i++) {
                        const message = history[i]
                        if (message.role === "user" || message.role === "assistant")
                            chatMessages.append({ role: message.role, content: message.content })
                    }
                }
            }
            catch (e) {
                // Corrupted history, do a fresh start
                console.warn("Could not restore chat history:", e)
            }
        }

        // Jump to the latest message
        chatView.scrollToBottom()
    }

    // Store the current conversation. Entries that are not real chat messages
    // (the typing indicator, error bubbles) are not saved.
    function saveHistory() {
        let history = []

        for (let i = 0; i < chatMessages.count; i++) {
            const item = chatMessages.get(i)

            if (item.role === "system" || item.role === "user" || item.role === "assistant")
                history.push({ role: item.role, content: item.content })
        }

        app.settings.setValue(chatHistoryKey, JSON.stringify(history))
    }

    function removeTypingIndicator() {
        const last = chatMessages.get(chatMessages.count - 1)

        if (last && last.role === "typing")
            chatMessages.remove(chatMessages.count - 1)
    }

    function sendMessage(message) {
        if (app.busy || message.trim() === "")
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
        // The typing indicator is an internal entry that shows activity
        // until the API response arrives. It is removed again below.
        chatMessages.append({
                        role: "typing",
                        content: ""
                      })
        chatView.scrollToBottom()
        saveHistory()

        app.busy = true

        chatApi.request(apiUrl, apiKey, apiModel,
                        chatApi.listModelToArray(chatMessages),
                        answer => {
                            removeTypingIndicator()
                            app.busy = false

                            chatMessages.append({
                                                  role: "assistant",
                                                  content: answer
                                                })

                            chatView.scrollToBottom()
                            saveHistory()
                        },
                        error => {
                            removeTypingIndicator()
                            app.busy = false

                            chatMessages.append({
                                                  role: "error",
                                                  content: error
                                                })

                            chatView.scrollToBottom()
                        })
    }

    function clearChat() {
        chatMessages.clear()
        chatMessages.append({ role: "system", content: systemPrompt })

        app.settings.setValue(chatHistoryKey, "")

        chatView.scrollToBottom()
    }

    ChatApi {
        id: chatApi
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
                title: "Clear chat"

                onClicked: clearDialog.open()
            }

            SettingsDialog {
                id: settingsDialog
                settingsStore: app.settings
            }

            Dialog {
                id: clearDialog

                title: "Clear chat"

                positiveAction: true
                positiveActionLabel: "Clear"
                negativeAction: true
                negativeActionLabel: "Cancel"

                onAccepted: {
                    clearChat()
                    close()
                }
                onCanceled: close()

                AppText {
                    text: "Are you sure you want to clear all chat history so far?"
                    padding: dp(20)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }

            ChatView {
                id: chatView
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: messageInput.top
                    margins: dp(20)
                }

                messages: chatMessages
            }

            InputBar {
                id: messageInput

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: dp(20)
                }

                busy: app.busy

                onSendRequested: message => sendMessage(message)
            }
        }

    }
}
