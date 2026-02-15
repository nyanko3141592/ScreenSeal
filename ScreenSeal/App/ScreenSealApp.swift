import SwiftUI

@main
struct ScreenSealApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("ScreenSeal", systemImage: "square.grid.3x3.fill") {
            MenuBarView()
                .environmentObject(appDelegate.windowManager)
        }
    }
}
