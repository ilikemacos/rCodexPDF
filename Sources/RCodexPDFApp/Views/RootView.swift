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

    var body: some View {
        List(selection: $appState.selectedSection) {
            Section("Workspace") {
                ForEach(SidebarSection.allCases) { section in
                    Label(section.rawValue, systemImage: section.symbol).tag(section)
                }
            }

            if !appState.settings.recentPDFs().isEmpty {
                Section("Recent PDFs") {
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
                Section("Recent Files") {
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
        }
        .listStyle(.sidebar)
        .navigationTitle("rCodexPDF")
    }
}
