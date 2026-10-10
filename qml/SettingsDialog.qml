import Felgo
import QtQuick
import QtQuick.Controls as Controls

Dialog {
    title: "Settings"

    readonly property string apiUrl: "apiUrl"
    readonly property string apiKey: "apiKey"
    readonly property string apiModel: "apiModel"

    // Cached list of model names fetched from the server, so the dropdown
    // is also populated on the next app start without a new request.
    readonly property string apiModels: "apiModels"

    required property var settingsStore

    positiveAction: true
    positiveActionLabel: "Save"
    negativeAction: true
    negativeActionLabel: "Cancel"

    property string errorText: ""
    property bool fetchingModels: false
    property var modelList: []

    onOpening: {
        urlField.text = settingsStore.getValue(apiUrl) || ""
        keyField.text = settingsStore.getValue(apiKey) || ""

        let saved = []
        try {
            saved = JSON.parse(settingsStore.getValue(apiModels) || "[]")
        } catch (e) {
            saved = []
        }
        if (!Array.isArray(saved))
            saved = []
        modelList = saved

        // Restore the last used model. If it is part of the fetched list,
        // select it in the dropdown, otherwise put it in the edit field.
        const savedModel = settingsStore.getValue(apiModel) || ""
        modelBox.currentIndex = modelBox.find(savedModel)
        if (modelBox.currentIndex === -1)
            modelBox.editText = savedModel

        errorText = ""
    }
    onCanceled: close()
    onAccepted: {
        // With an editable ComboBox, editText always contains the currently
        // displayed text, no matter if it was selected or typed.
        const modelValue = modelBox.editText.trim()

        if(urlField.text.trim() === ""
                || keyField.text.trim() === ""
                || modelValue === "") {
            errorText = "All fields are required"
            return
        }

        settingsStore.setValue(apiUrl, urlField.text.trim())
        settingsStore.setValue(apiKey, keyField.text.trim())
        settingsStore.setValue(apiModel, modelValue)

        close()
    }

    // Fetching the model list from the /models endpoint doubles as a
    // connection test: if it succeeds, the URL and key are valid.
    function fetchModels() {
        const url = urlField.text.trim().replace(/\/+$/, "")
        const key = keyField.text.trim()

        if (url === "" || key === "") {
            errorText = "Enter the API URL and key before fetching models."
            return
        }

        fetchingModels = true
        errorText = ""

        HttpRequest
            .get(url + "/models")
            .timeout(10000)
            .set("Authorization", "Bearer " + key)
            .then(res => {
                      fetchingModels = false

                      const data = res.body && res.body.data ? res.body.data : []
                      const ids = []

                      for (let i = 0; i < data.length; i++) {
                          if (data[i] && data[i].id)
                              ids.push(data[i].id)
                      }

                      modelList = ids
                      settingsStore.setValue(apiModels, JSON.stringify(ids))

                      if (ids.length > 0) {
                          modelBox.currentIndex = 0
                          errorText = ""
                      }
                      else {
                          errorText = "The server did not return any models. You can type a model name manually."
                      }
                  })
            .catch(err => {
                       fetchingModels = false
                       errorText = "Could not fetch models. Check the URL and key, or type a model name manually."
                   })
    }

    Column {
        width: dp(280)
        spacing: dp(8)

        AppTextField {
            id: urlField
            width: parent.width
            placeholderText: "API base URL"
            onTextChanged: errorText = ""
        }

        AppTextField {
            id: keyField
            width: parent.width
            placeholderText: "API key (Gibberish for local API)"
            onTextChanged: errorText = ""
        }

        // The fetch button sits next to the dropdown, since fetching the
        // model list is only ever needed together with the dropdown.
        Row {
            width: parent.width
            spacing: dp(8)

            Controls.ComboBox {
                id: modelBox

                width: parent.width - fetchButton.width - parent.spacing
                editable: true
                model: modelList
            }

            AppButton {
                id: fetchButton

                width: dp(90)
                height: modelBox.height
                text: fetchingModels ? "..." : "Fetch"
                enabled: !fetchingModels

                onClicked: fetchModels()
            }
        }

        AppText {
            width: parent.width
            visible: errorText !== ""
            text: errorText
            color: "red"
            wrapMode: Text.WordWrap
        }
    }
}
