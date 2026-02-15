import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let windowManager = WindowManager()
    private let permissionManager = PermissionManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            await permissionManager.requestPermissionIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager.removeAllWindows()
    }
}
