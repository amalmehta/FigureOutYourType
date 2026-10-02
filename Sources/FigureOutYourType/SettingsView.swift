import SwiftUI
import TypeCore

struct SettingsView: View {
    @State private var key = ""
    @State private var status = APIKeyStore.hasSavedKey ? "A key is saved in your Keychain." : "No key saved yet."

    var body: some View {
        Form {
            Section {
                SecureField("Anthropic API key", text: $key, prompt: Text("sk-ant-…"))
                HStack {
                    Button("Save") {
                        status = APIKeyStore.save(key) ? "Saved to your Keychain." : "Couldn't save to the Keychain."
                        key = ""
                    }
                    .disabled(key.isEmpty)
                    Button("Remove Saved Key") {
                        APIKeyStore.delete()
                        status = "Key removed."
                    }
                }
                Text(status).font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("Claude")
            } footer: {
                Text("Photos and notes are sent to Anthropic's API (\(TypeAnalyzer.model)) only when you click Figure Out My Type. Get a key at console.anthropic.com.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }
}
