import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var windowManager: WindowManager

    var body: some View {
        Button("New Mosaic Window") {
            windowManager.createWindow()
        }
        .keyboardShortcut("n")

        Divider()

        // Window list
        if !windowManager.windows.isEmpty {
            ForEach(windowManager.windows, id: \.windowIndex) { window in
                Button {
                    windowManager.toggleWindow(window)
                } label: {
                    HStack {
                        Image(systemName: window.isVisible ? "eye.fill" : "eye.slash")
                            .frame(width: 16)
                        Text(window.displayName)
                        Spacer()
                        Text(window.configuration.mosaicType.rawValue)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }

            Divider()

            Button("Remove All Windows") {
                windowManager.removeAllWindows()
            }

            Divider()
        }

        // Presets
        if windowManager.windows.isEmpty {
            Divider()
        }

        Button("Save Current Layout...") {
            promptSavePreset()
        }
        .disabled(windowManager.windows.isEmpty)

        let presets = windowManager.presetManager.presets
        if !presets.isEmpty {
            Menu("Load Preset") {
                ForEach(presets) { preset in
                    Button("\(preset.name) (\(preset.windows.count) windows)") {
                        windowManager.loadPreset(preset)
                    }
                }
            }

            Menu("Delete Preset") {
                ForEach(presets) { preset in
                    Button(preset.name, role: .destructive) {
                        windowManager.presetManager.delete(preset)
                        windowManager.objectWillChange.send()
                    }
                }
            }
        }

        if let error = windowManager.captureError {
            Divider()
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
        }

        Divider()

        Button("Quit ScreenSeal") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func promptSavePreset() {
        let alert = NSAlert()
        alert.messageText = "Save Layout Preset"
        alert.informativeText = "Enter a name for this layout:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        textField.placeholderString = "Preset name"
        let count = windowManager.presetManager.presets.count + 1
        textField.stringValue = "Preset \(count)"
        alert.accessoryView = textField

        alert.window.initialFirstResponder = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let name = textField.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                windowManager.saveCurrentLayout(name: name)
            }
        }
    }
}
