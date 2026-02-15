import ScreenCaptureKit
import CoreImage
import os.log

private let logger = Logger(subsystem: "com.screenseal.app", category: "ScreenCapture")

final class ScreenCaptureService: NSObject {
    private var streams: [CGDirectDisplayID: SCStream] = [:]
    private var streamOutputs: [CGDirectDisplayID: StreamOutput] = [:]
    private var isRunning = false

    var onFrame: ((CIImage, CGDirectDisplayID) -> Void)?
    var onError: ((String) -> Void)?

    func startCapture() async {
        guard !isRunning else { return }
        isRunning = true

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

            guard !content.displays.isEmpty else {
                logger.error("No display found")
                onError?("No display found")
                isRunning = false
                return
            }

            let selfBundleID = Bundle.main.bundleIdentifier ?? ""
            let excludedApps = content.applications.filter { $0.bundleIdentifier == selfBundleID }

            for display in content.displays {
                let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

                let config = SCStreamConfiguration()
                let scaleFactor: CGFloat = await MainActor.run {
                    NSScreen.screens
                        .first(where: { $0.displayID == display.displayID })?
                        .backingScaleFactor ?? 2.0
                }
                config.width = Int(CGFloat(display.width) * scaleFactor)
                config.height = Int(CGFloat(display.height) * scaleFactor)
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.showsCursor = false
                config.queueDepth = 3

                let output = StreamOutput(displayID: display.displayID)
                output.onFrame = { [weak self] image, id in
                    self?.onFrame?(image, id)
                }

                let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
                try await stream.startCapture()

                streams[display.displayID] = stream
                streamOutputs[display.displayID] = output

                logger.info("Started capture for display \(display.displayID)")
            }
        } catch {
            logger.error("Failed to start capture: \(error.localizedDescription)")
            onError?("Screen capture failed: \(error.localizedDescription)")
            isRunning = false
        }
    }

    func stopCapture() async {
        let currentStreams = streams
        streams.removeAll()
        streamOutputs.removeAll()
        isRunning = false

        for (displayID, stream) in currentStreams {
            do {
                try await stream.stopCapture()
                logger.info("Stopped capture for display \(displayID)")
            } catch {
                logger.error("Failed to stop capture for display \(displayID): \(error.localizedDescription)")
            }
        }
    }

    func updateExclusion() async {
        guard !streams.isEmpty else { return }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            let selfBundleID = Bundle.main.bundleIdentifier ?? ""
            let excludedApps = content.applications.filter { $0.bundleIdentifier == selfBundleID }

            for (displayID, stream) in streams {
                guard let display = content.displays.first(where: { $0.displayID == displayID }) else { continue }
                let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
                try await stream.updateContentFilter(filter)
            }
        } catch {
            logger.error("Failed to update exclusion: \(error.localizedDescription)")
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
