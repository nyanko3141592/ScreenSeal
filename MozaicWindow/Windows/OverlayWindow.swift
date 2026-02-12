import AppKit

final class OverlayWindow: NSWindow {
    let configuration = OverlayConfiguration()
    let overlayContentView: OverlayContentView

    init(contentRect: NSRect) {
        overlayContentView = OverlayContentView(frame: contentRect, configuration: configuration)

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        sharingType = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 80, height: 80)

        contentView = overlayContentView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func lockPosition() {
        isMovable = false
        isMovableByWindowBackground = false
        styleMask.remove(.resizable)
    }

    func unlockPosition() {
        isMovable = true
        isMovableByWindowBackground = true
        styleMask.insert(.resizable)
    }
}
