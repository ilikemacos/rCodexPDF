import SwiftUI
import RCodexPDFCore

struct PDFContainerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if appState.openPDFs.isEmpty {
                EmptyPDFStateView()
            } else {
                PDFTabBar()
                Divider()
                if let doc = appState.activePDF {
                    PDFDocumentView(doc: doc)
                        .id(doc.id)
                }
            }
        }
        .toolbar {
            if appState.activePDF != nil {
                PDFToolbar()
            }
        }
    }
}

struct EmptyPDFStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No PDF Open")
                .font(.title2.bold())
            Text("Drag and drop a PDF here, or open one from the toolbar.")
                .foregroundStyle(.secondary)
            Button("Open PDF…") { appState.presentOpenPDFPanel() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PDFTabBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appState.openPDFs) { doc in
                    PDFTabButton(doc: doc)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(.bar)
    }
}

struct PDFTabButton: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var doc: OpenPDFDocument

    var isActive: Bool { appState.activePDFID == doc.id }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.richtext")
            Text(doc.title).lineLimit(1)
            Button {
                appState.closePDF(doc)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { appState.activePDFID = doc.id }
    }
}

struct PDFToolbar: ToolbarContent {
    @EnvironmentObject var appState: AppState

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                appState.activePDF?.sidebarMode = appState.activePDF?.sidebarMode == .thumbnails ? .none : .thumbnails
            } label: { Image(systemName: "square.grid.2x2") }
            .help("Toggle thumbnails")

            Button {
                appState.activePDF?.sidebarMode = appState.activePDF?.sidebarMode == .outline ? .none : .outline
            } label: { Image(systemName: "list.bullet.indent") }
            .help("Toggle outline/bookmarks")

            Button { appState.activePDF?.isSearchVisible.toggle() } label: {
                Image(systemName: "magnifyingglass")
            }.help("Find in PDF")

            Divider()

            Button { appState.activePDF?.zoomOut() } label: { Image(systemName: "minus.magnifyingglass") }
            Button { appState.activePDF?.zoomIn() } label: { Image(systemName: "plus.magnifyingglass") }
            Button { appState.activePDF?.rotate() } label: { Image(systemName: "rotate.right") }

            Divider()

            Button { appState.activePDF?.print() } label: { Image(systemName: "printer") }
                .help("Print")
        }
    }
}

struct PDFDocumentView: View {
    @ObservedObject var doc: OpenPDFDocument

    var body: some View {
        HStack(spacing: 0) {
            if doc.sidebarMode == .thumbnails {
                PDFThumbnailSidebar(doc: doc)
                    .frame(width: 180)
                Divider()
            } else if doc.sidebarMode == .outline {
                PDFOutlineSidebar(doc: doc)
                    .frame(width: 220)
                Divider()
            }

            VStack(spacing: 0) {
                if doc.isSearchVisible {
                    PDFSearchBar(doc: doc)
                    Divider()
                }
                PDFKitRepresentable(pdfView: doc.pdfView)
            }
        }
        .sheet(isPresented: $doc.isPasswordPromptVisible) {
            PDFPasswordPromptView(doc: doc)
        }
    }
}

struct PDFPasswordPromptView: View {
    @ObservedObject var doc: OpenPDFDocument
    @State private var password = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.doc").font(.system(size: 40))
            Text("\"\(doc.title)\" is password protected").font(.headline)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .onSubmit(unlock)
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }
            HStack {
                Button("Cancel") { dismiss() }
                Button("Unlock", action: unlock).buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func unlock() {
        if doc.unlock(password: password) {
            errorMessage = nil
        } else {
            errorMessage = "Incorrect password."
        }
    }
}
