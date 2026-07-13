import SwiftUI
import RCodexPDFCore

struct BuildOutputPanel: View {
    @ObservedObject var file: OpenCodeFile
    @State private var tab: Tab = .output

    enum Tab: String, CaseIterable { case output = "Output", diagnostics = "Diagnostics" }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Spacer()

                if file.isRunning {
                    ProgressView().controlSize(.small)
                    Text("Running…").font(.caption).foregroundStyle(.secondary)
                }

                Button {
                    file.outputLines.removeAll()
                    file.diagnostics.removeAll()
                } label: { Image(systemName: "trash") }
                    .buttonStyle(.plain)
                    .help("Clear output")
            }
            .padding(6)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    switch tab {
                    case .output:
                        ForEach(file.outputLines) { line in
                            Text(line.text)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(line.isError ? .red : .primary)
                                .textSelection(.enabled)
                        }
                    case .diagnostics:
                        if file.diagnostics.isEmpty {
                            Text("No diagnostics").font(.caption).foregroundStyle(.secondary).padding(4)
                        }
                        ForEach(file.diagnostics) { diagnostic in
                            DiagnosticRow(diagnostic: diagnostic)
                        }
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.background)
    }
}

private struct DiagnosticRow: View {
    let diagnostic: CompilerDiagnostic

    var icon: String {
        switch diagnostic.severity {
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .note: return "info.circle.fill"
        }
    }

    var color: Color {
        switch diagnostic.severity {
        case .error: return .red
        case .warning: return .yellow
        case .note: return .blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text("\((diagnostic.file as NSString).lastPathComponent):\(diagnostic.line)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text(diagnostic.message)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
}
