import AppKit

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let id = deviceDescription[key] as? CGDirectDisplayID else {
            return CGMainDisplayID()
        }
        return id
    }
}
