import SwiftUI
import RCodexPDFCore

struct EditorContainerView: View {
    @EnvironmentObject var appState: AppState
    @State private var showMinimap = true

    var body: some View {
        VStack(spacing: 0) {
            if appState.openCodeFiles.isEmpty {
                EmptyEditorStateView()
            } else {
                EditorTabBar()
                Divider()
                if let file = appState.activeCodeFile {
                    EditorSplitView(file: file, showMinimap: showMinimap)
                }
            }
        }
        .toolbar {
            if appState.activeCodeFile != nil {
                EditorToolbar(showMinimap: $showMinimap)
            }
        }
    }
}

struct EmptyEditorStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 56)).foregroundStyle(.secondary)
            Text("No File Open").font(.title2.bold())
            HStack {
                Button("Open File…") { appState.presentOpenCodeFilePanel() }
                Button("New File") { appState.newCodeFile() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EditorTabBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appState.openCodeFiles) { file in
                    EditorTabButton(file: file)
                }
                Button { appState.newCodeFile() } label: { Image(systemName: "plus") }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(.bar)
    }
}

struct EditorTabButton: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var file: OpenCodeFile

    var isActive: Bool { appState.activeCodeFileID == file.id }

    var body: some View {
        HStack(spacing: 6) {
            Text(file.title + (file.isDirty ? " •" : "")).lineLimit(1)
            Button { appState.closeCodeFile(file) } label: {
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { appState.activeCodeFileID = file.id }
    }
}

struct EditorToolbar: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @Binding var showMinimap: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                appState.activeCodeFile?.run()
            } label: { Image(systemName: "play.fill") }
                .help("Run")
                .disabled(appState.activeCodeFile?.isRunning ?? true)

            Button {
                appState.activeCodeFile?.stop()
            } label: { Image(systemName: "stop.fill") }
                .help("Stop")
                .disabled(!(appState.activeCodeFile?.isRunning ?? false))

            Button {
                appState.activeCodeFile?.format()
            } label: { Image(systemName: "text.alignleft") }
                .help("Format")

            Divider()

            Button { showMinimap.toggle() } label: { Image(systemName: "map") }
                .help("Toggle minimap")

            if let file = appState.activeCodeFile, let url = file.url {
                Text(url.lastPathComponent).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct EditorSplitView: View {
    @ObservedObject var file: OpenCodeFile
    let showMinimap: Bool
    @EnvironmentObject var appState: AppState
    @State private var outputHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                CodeTextView(
                    text: Binding(
                        get: { file.content },
                        set: { newValue in
                            file.content = newValue
                            file.markDirty()
                        }
                    ),
                    language: file.language,
                    theme: appState.settings.editorTheme,
                    fontSize: appState.settings.editorFontSize
                )

                if showMinimap {
                    Divider()
                    MinimapView(text: file.content) { _ in }
                        .frame(width: 90)
                }
            }
            Divider()
            BuildOutputPanel(file: file)
                .frame(height: outputHeight)
        }
    }
}
