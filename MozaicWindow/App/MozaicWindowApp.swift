import SwiftUI

@main
struct MozaicWindowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("MozaicWindow", systemImage: "square.grid.3x3.fill") {
            MenuBarView()
                .environmentObject(appDelegate.windowManager)
        }
    }
}
