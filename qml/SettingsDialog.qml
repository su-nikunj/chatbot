import Felgo
import QtQuick

Dialog {
    title: "Settings"

    readonly property string apiUrl: "apiUrl"
    readonly property string apiKey: "apiKey"
    readonly property string apiModel: "apiModel"

    required property var settingsStore

    positiveAction: true
    positiveActionLabel: "Save"
    negativeAction: true
    negativeActionLabel: "Cancel"

    property bool showValidationError: false

    onOpening: {
        urlField.text = settingsStore.getValue(apiUrl) || ""
        keyField.text = settingsStore.getValue(apiKey) || ""
        modelField.text = settingsStore.getValue(apiModel) || ""

        showValidationError = false
    }
    onCanceled: close()
    onAccepted: {
        if(urlField.text.trim() === ""
                || keyField.text.trim() === ""
                || modelField.text.trim() === "") {
            showValidationError = true
            return
        }

        settingsStore.setValue(apiUrl, urlField.text.trim())
        settingsStore.setValue(apiKey, keyField.text.trim())
        settingsStore.setValue(apiModel, modelField.text.trim())

        close()
    }

    Column {
        width: dp(280)
        height: dp(12)

        AppTextField {
            id: urlField
            width: parent.width
            placeholderText: "API base URL"
            onTextChanged: showValidationError = false
        }

        AppTextField {
            id: keyField
            width: parent.width
            placeholderText: "API key (Gibberish for local API)"
            onTextChanged: showValidationError = false
        }

        AppTextField {
            id: modelField
            width: parent.width
            placeholderText: "Model name (e.g. gpt-6-astra)"
            onTextChanged: showValidationError = false
        }

        AppText {
            width: parent.width
            visible: showValidationError
            text: "All fields are required"
            color: "red"
            wrapMode: Text.WordWrap
        }
    }
}
