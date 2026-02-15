import ScreenCaptureKit
import os.log

private let logger = Logger(subsystem: "com.screenseal.app", category: "Permission")

final class PermissionManager {
    func requestPermissionIfNeeded() async {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            logger.info("Screen capture permission granted")
        } catch {
            logger.warning("Screen capture permission not granted: \(error.localizedDescription)")
        }
    }

    func hasPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            return true
        } catch {
            return false
        }
    }
}
