import SwiftUI
import RCodexPDFCore

struct SettingsAppearanceSection: View {
    @ObservedObject var holder: SettingsHolder

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                labeledSection(holder.tr("appearance.mode")) {
                    Picker(holder.tr("appearance.mode"), selection: $holder.appearanceMode) {
                        Text(holder.tr("appearance.mode.system")).tag(AppearanceMode.system)
                        Text(holder.tr("appearance.mode.light")).tag(AppearanceMode.light)
                        Text(holder.tr("appearance.mode.dark")).tag(AppearanceMode.dark)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 320)
                }

                labeledSection(holder.tr("appearance.fontSize")) {
                    Picker(holder.tr("appearance.fontSize"), selection: $holder.uiFontSizePreset) {
                        ForEach(UIFontSizePreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 320)
                }

                labeledSection(holder.tr("appearance.language")) {
                    Picker(holder.tr("appearance.language"), selection: $holder.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.nativeLabel).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }

                Divider().padding(.vertical, 4)

                labeledSection(holder.tr("appearance.editorTheme")) {
                    Picker(holder.tr("appearance.editorTheme"), selection: $holder.editorTheme) {
                        ForEach(EditorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: 200)
                }

                labeledSection(holder.tr("appearance.editorFontSize")) {
                    HStack {
                        Stepper(value: $holder.editorFontSize, in: 9...24, step: 1) {
                            Text("\(Int(holder.editorFontSize))pt")
                        }
                        .frame(maxWidth: 160)
                    }
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func labeledSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.callout.weight(.semibold))
            content()
        }
    }
}
