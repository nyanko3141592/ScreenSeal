import AppKit
import Combine

final class WindowManager: ObservableObject {
    @Published private(set) var windows: [OverlayWindow] = []
    private var screenCaptureService: ScreenCaptureService?

    func createWindow() {
        let defaultSize = NSRect(x: 200, y: 200, width: 300, height: 200)
        let window = OverlayWindow(contentRect: defaultSize)
        windows.append(window)
        window.makeKeyAndOrderFront(nil)

        startCaptureIfNeeded()
        registerWindow(window)
    }

    func removeWindow(_ window: OverlayWindow) {
        window.orderOut(nil)
        windows.removeAll { $0 === window }
        if windows.isEmpty {
            stopCapture()
        }
    }

    func removeAllWindows() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        stopCapture()
    }

    private func startCaptureIfNeeded() {
        guard screenCaptureService == nil else { return }
        let service = ScreenCaptureService()
        screenCaptureService = service
        service.onFrame = { [weak self] frame, displayID in
            self?.distributeFrame(frame, displayID: displayID)
        }
        Task {
            await service.startCapture()
        }
    }

    private func stopCapture() {
        Task {
            await screenCaptureService?.stopCapture()
        }
        screenCaptureService = nil
    }

    private func registerWindow(_ window: OverlayWindow) {
        // Update capture exclusion to include the new window
        Task {
            await screenCaptureService?.updateExclusion()
        }
    }

    private func distributeFrame(_ frame: CIImage, displayID: CGDirectDisplayID) {
        let frameExtent = frame.extent

        for window in windows {
            guard let screen = window.screen, screen.displayID == displayID else { continue }

            let windowRect = window.frame
            let screenFrame = screen.frame

            // Use actual captured frame size for scale (handles notch, menu bar differences)
            let scaleX = frameExtent.width / screenFrame.width
            let scaleY = frameExtent.height / screenFrame.height

            // Both NSWindow and CIImage use bottom-left origin, no Y flip needed
            let localX = windowRect.origin.x - screenFrame.origin.x
            let localY = windowRect.origin.y - screenFrame.origin.y

            let captureX = localX * scaleX
            let captureY = localY * scaleY
            let captureW = windowRect.width * scaleX
            let captureH = windowRect.height * scaleY

            let cropRect = CGRect(x: captureX, y: captureY, width: captureW, height: captureH)
                .intersection(frameExtent)

            guard !cropRect.isEmpty else { continue }

            let cropped = frame.cropped(to: cropRect)
                .transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))

            DispatchQueue.main.async {
                window.overlayContentView.updateFrame(cropped)
            }
        }
    }
}
