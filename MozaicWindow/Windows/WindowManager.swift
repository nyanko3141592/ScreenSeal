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
        for window in windows {
            guard let screen = window.screen, screen.displayID == displayID else { continue }

            let windowRect = window.frame
            let screenFrame = screen.frame
            let backingScale = screen.backingScaleFactor

            // Convert NSWindow coords (bottom-left origin) to screen capture coords (top-left origin)
            let captureX = (windowRect.origin.x - screenFrame.origin.x) * backingScale
            let captureY = (screenFrame.height - (windowRect.origin.y - screenFrame.origin.y) - windowRect.height) * backingScale
            let captureW = windowRect.width * backingScale
            let captureH = windowRect.height * backingScale

            let cropRect = CGRect(x: captureX, y: captureY, width: captureW, height: captureH)
                .intersection(frame.extent)

            guard !cropRect.isEmpty else { continue }

            let cropped = frame.cropped(to: cropRect)
                .transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))

            DispatchQueue.main.async {
                window.overlayContentView.updateFrame(cropped)
            }
        }
    }
}
