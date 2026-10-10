import Felgo
import QtQuick

// Encapsulates everything related to the chat completions API
Item {
    id: root

    // Converts a chat message model into the plain array that the API
    // expects. Only roles that the API understands are part of the request.
    // Internal entries like the typing indicator or error bubbles are
    // filtered out here.
    function listModelToArray(model) {
        const allowedRoles = [ "system", "user", "assistant" ]

        let result = []

        for (let i = 0; i < model.count; i++) {
            const item = model.get(i)

            if (allowedRoles.indexOf(item.role) !== -1)
                result.push({ role: item.role, content: item.content })
        }

        return result
    }

    // Build a readable error message for the chat view
    function requestErrorMessage(err) {
        const body = err && err.response ? err.response.body : null

        if (body && body.error && body.error.message)
            return body.error.message

        if (err && err.status === 0)
            return "Could not reach the server. Check the API URL and your connection."

        return err && err.message ? err.message : "Request failed. Please try again."
    }

    // Sends the conversation to the API and reports the result with the
    // onSuccess(answer) or onError(message) callback.
    function request(url, apiKey, model, messages, onSuccess, onError) {
        const chatUrl = url.replace(/\/+$/, "") + "/chat/completions"

        HttpRequest
            .post(chatUrl)
            .timeout(30000)
            .set("Content-Type", "application/json")
            .set("Authorization", `Bearer ${apiKey}`)
            .send({
                      model: model,
                      messages: messages,
                      temperature: 0.7
                  })
            .then(res => {
                      if (res.body && res.body.choices && res.body.choices.length > 0
                              && res.body.choices[0].message) {
                          onSuccess(res.body.choices[0].message.content)
                      }
                      else {
                          // The request went through, but the answer is not
                          // what we expect from an OpenAI compatible API.
                          onError("The server returned an unexpected response.")
                      }
                  })
            .catch(err => onError(requestErrorMessage(err)))
    }
}
