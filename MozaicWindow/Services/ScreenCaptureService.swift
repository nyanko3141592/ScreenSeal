import ScreenCaptureKit
import CoreImage

final class ScreenCaptureService: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    var onFrame: ((CIImage, CGDirectDisplayID) -> Void)?

    func startCapture() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

            guard let display = content.displays.first else {
                print("No display found")
                return
            }

            // Exclude our own app's windows
            let selfBundleID = Bundle.main.bundleIdentifier ?? ""
            let excludedApps = content.applications.filter { $0.bundleIdentifier == selfBundleID }

            let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

            let config = SCStreamConfiguration()
            config.width = display.width * 2  // Retina
            config.height = display.height * 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30fps
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false
            config.queueDepth = 3

            let output = StreamOutput(displayID: display.displayID)
            output.onFrame = { [weak self] image, id in
                self?.onFrame?(image, id)
            }
            streamOutput = output

            let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
            try newStream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
            try await newStream.startCapture()
            stream = newStream
        } catch {
            print("Failed to start capture: \(error.localizedDescription)")
        }
    }

    func stopCapture() async {
        do {
            try await stream?.stopCapture()
        } catch {
            print("Failed to stop capture: \(error.localizedDescription)")
        }
        stream = nil
        streamOutput = nil
    }

    func updateExclusion() async {
        guard let stream = stream else { return }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            guard let display = content.displays.first else { return }

            let selfBundleID = Bundle.main.bundleIdentifier ?? ""
            let excludedApps = content.applications.filter { $0.bundleIdentifier == selfBundleID }

            let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
            try await stream.updateContentFilter(filter)
        } catch {
            print("Failed to update exclusion: \(error.localizedDescription)")
        }
    }
}

// MARK: - Stream Output

private final class StreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    let displayID: CGDirectDisplayID
    var onFrame: ((CIImage, CGDirectDisplayID) -> Void)?

    init(displayID: CGDirectDisplayID) {
        self.displayID = displayID
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let pixelBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        onFrame?(ciImage, displayID)
    }
}
