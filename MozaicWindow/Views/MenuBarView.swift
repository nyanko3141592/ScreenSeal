import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var windowManager: WindowManager

    var body: some View {
        Button("New Mosaic Window") {
            windowManager.createWindow()
        }
        .keyboardShortcut("n")

        Divider()

        Button("Remove All Windows") {
            windowManager.removeAllWindows()
        }
        .disabled(windowManager.windows.isEmpty)

        Divider()

        Button("Quit MozaicWindow") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
