import AppKit

final class OverlayWindow: NSWindow {
    let configuration = OverlayConfiguration()
    let overlayContentView: OverlayContentView
    let windowIndex: Int
    private var didMoveObserver: Any?

    var displayName: String {
        "Mosaic #\(windowIndex)"
    }

    init(contentRect: NSRect, index: Int) {
        self.windowIndex = index
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
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 80, height: 80)

        contentView = overlayContentView

        didMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.overlayContentView.windowDidMove()
        }
    }

    deinit {
        if let observer = didMoveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
