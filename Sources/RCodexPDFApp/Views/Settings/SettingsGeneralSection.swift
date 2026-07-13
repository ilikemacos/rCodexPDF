import SwiftUI
import RCodexPDFCore

struct SettingsGeneralSection: View {
    @ObservedObject var holder: SettingsHolder
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(holder.tr("general.rememberLastPage"), isOn: $holder.pdfRememberLastPage)
                Toggle(holder.tr("general.autoSave"), isOn: $holder.autoSaveEnabled)
                Toggle(holder.tr("general.coloredCLI"), isOn: $holder.cliColorOutput)

                Divider().padding(.vertical, 4)

                Toggle(holder.tr("general.autoUpdate"), isOn: $holder.autoCheckForUpdates)
                Button(holder.tr("general.checkNow")) {
                    Task { await appState.updateViewModel.checkManually() }
                }
                .disabled(appState.updateViewModel.isChecking)
            }
            .padding(20)
        }
    }
}
