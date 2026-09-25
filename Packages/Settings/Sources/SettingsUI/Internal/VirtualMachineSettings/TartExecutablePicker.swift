import SwiftUI

struct TartExecutablePicker: View {
    @Binding var executableURL: URL?
    let resolvedExecutablePath: String?
    let isEnabled: Bool

    @State private var hasInvalidSelection = false

    private var displayedPath: String {
        executableURL?.path(percentEncoded: false)
            ?? resolvedExecutablePath
            ?? L10n.Settings.VirtualMachine.TartExecutable.notFound
    }

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                HStack {
                    Text(displayedPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(displayedPath)
                    Button {
                        selectExecutable()
                    } label: {
                        Text(L10n.Settings.VirtualMachine.TartExecutable.selectFile)
                            .fixedSize()
                    }
                    Button {
                        executableURL = nil
                        hasInvalidSelection = false
                    } label: {
                        Text(L10n.Settings.VirtualMachine.TartExecutable.resetToDefault)
                            .fixedSize()
                    }
                }
                .disabled(!isEnabled)
            } label: {
                Text(L10n.Settings.VirtualMachine.TartExecutable.file)
            }
            if hasInvalidSelection {
                Text(L10n.Settings.VirtualMachine.TartExecutable.invalidFile)
                    .foregroundStyle(.red)
            }
        }
    }
}

private extension TartExecutablePicker {
    func selectExecutable() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.showsHiddenFiles = true
        openPanel.directoryURL = executableURL?.deletingLastPathComponent()
        guard openPanel.runModal() == .OK, let selectedURL = openPanel.url else {
            return
        }
        guard FileManager.default.isExecutableFile(atPath: selectedURL.path(percentEncoded: false)) else {
            hasInvalidSelection = true
            return
        }
        hasInvalidSelection = false
        executableURL = selectedURL
    }
}
