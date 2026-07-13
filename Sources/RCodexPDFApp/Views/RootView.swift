import SwiftUI
import RCodexPDFCore

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            switch appState.selectedSection {
            case .pdf:
                PDFContainerView()
            case .editor:
                EditorContainerView()
            case .chat:
                ChatView()
            case .settings:
                SettingsContainerView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .sheet(isPresented: $appState.updateViewModel.isPresented) {
            UpdateSheet(viewModel: appState.updateViewModel)
        }
        .task {
            await appState.updateViewModel.checkOnLaunchIfDue()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async {
                    appState.open(url: url)
                }
            }
        }
        return true
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var holder = SettingsHolder.shared
    @Environment(\.uiFontScale) private var fontScale

    private var mainSections: [SidebarSection] { [.pdf, .editor, .chat] }

    var body: some View {
        List(selection: $appState.selectedSection) {
            Section(holder.tr("sidebar.workspace")) {
                ForEach(mainSections) { section in
                    Label(holder.tr(section.localizationKey), systemImage: section.symbol)
                        .font(.system(size: 13 * fontScale))
                        .tag(section)
                }
            }

            if !appState.settings.recentPDFs().isEmpty {
                Section(holder.tr("sidebar.recentPDFs")) {
                    ForEach(appState.settings.recentPDFs().prefix(8), id: \.self) { url in
                        Button {
                            appState.openPDF(url: url)
                        } label: {
                            Label(url.lastPathComponent, systemImage: "doc.text")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !appState.settings.recentFiles().isEmpty {
                Section(holder.tr("sidebar.recentFiles")) {
                    ForEach(appState.settings.recentFiles().prefix(8), id: \.self) { url in
                        Button {
                            appState.openCodeFile(url: url)
                        } label: {
                            Label(url.lastPathComponent, systemImage: "doc.plaintext")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Label(holder.tr(SidebarSection.settings.localizationKey), systemImage: SidebarSection.settings.symbol)
                    .font(.system(size: 13 * fontScale))
                    .tag(SidebarSection.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("rCodexPDF")
    }
}
