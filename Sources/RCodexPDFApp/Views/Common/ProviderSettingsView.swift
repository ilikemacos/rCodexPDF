import SwiftUI
import RCodexPDFCore

struct ProviderSettingsView: View {
    @State private var selectedProviderID: String = AIProviderRegistry.all.first?.id ?? "claude"

    var body: some View {
        HSplitView {
            List(AIProviderRegistry.all, id: \.id, selection: $selectedProviderID) { provider in
                HStack {
                    Text(provider.displayName)
                    Spacer()
                    if KeychainStore().hasAPIKey(for: provider.id) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    }
                }
                .tag(provider.id)
            }
            .frame(minWidth: 180)

            if let provider = AIProviderRegistry.provider(withID: selectedProviderID) {
                ProviderDetailView(provider: provider)
                    .frame(minWidth: 340)
            } else {
                Text("Select a provider").foregroundStyle(.secondary)
            }
        }
    }
}

private struct ProviderDetailView: View {
    let provider: any AIProvider
    private let keychain = KeychainStore()
    private let settings = AppSettings.shared

    @State private var apiKey: String = ""
    @State private var baseURLText: String = ""
    @State private var saveConfirmation = false

    var body: some View {
        Form {
            Section("API Key") {
                SecureField("sk-...", text: $apiKey)
                HStack {
                    Button("Save to Keychain") { save() }
                        .disabled(apiKey.isEmpty)
                    if keychain.hasAPIKey(for: provider.id) {
                        Button("Remove", role: .destructive) {
                            keychain.deleteAPIKey(for: provider.id)
                            apiKey = ""
                        }
                    }
                    if saveConfirmation {
                        Label("Saved", systemImage: "checkmark").foregroundStyle(.green).font(.caption)
                    }
                }
                Text("Stored securely in the macOS Keychain. Never written to disk in plain text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Endpoint") {
                TextField("Base URL", text: $baseURLText)
                    .onSubmit(saveBaseURL)
                Text("Default: \(provider.defaultBaseURL.absoluteString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Models") {
                ForEach(provider.availableModels, id: \.self) { model in
                    Text(model)
                }
            }
        }
        .padding(20)
        .onAppear(perform: load)
        .onChange(of: provider.id) { _ in load() }
    }

    private func load() {
        apiKey = ""
        baseURLText = settings.baseURLOverride(forProvider: provider.id)?.absoluteString ?? ""
        saveConfirmation = false
    }

    private func save() {
        try? keychain.setAPIKey(apiKey, for: provider.id)
        saveConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saveConfirmation = false }
    }

    private func saveBaseURL() {
        if baseURLText.isEmpty {
            settings.setBaseURLOverride(nil, forProvider: provider.id)
        } else if let url = URL(string: baseURLText) {
            settings.setBaseURLOverride(url, forProvider: provider.id)
        }
    }
}
