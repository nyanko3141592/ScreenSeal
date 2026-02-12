import ScreenCaptureKit

final class PermissionManager {
    func requestPermissionIfNeeded() async {
        do {
            // Requesting shareable content triggers the system permission dialog
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            print("Screen capture permission not granted: \(error.localizedDescription)")
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
