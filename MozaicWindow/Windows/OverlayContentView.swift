import AppKit
import Combine
import CoreImage

final class OverlayContentView: NSView {
    private let configuration: OverlayConfiguration
    private let filterProcessor = FilterProcessor()
    private let displayLayer = CALayer()
    private let cornerLayer = CAShapeLayer()
    private var cancellables = Set<AnyCancellable>()
    private var currentFrame: CIImage?
    private var trackingArea: NSTrackingArea?
    private var hasBeenMoved = false
    private var isMouseInside = false

    private static let cornerColor = NSColor.white.withAlphaComponent(0.9).cgColor
    private static let cornerLineWidth: CGFloat = 2.5
    private static let cornerLength: CGFloat = 16.0

    init(frame: NSRect, configuration: OverlayConfiguration) {
        self.configuration = configuration
        super.init(frame: frame)
        setupLayers()
        observeConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { false }

    private func setupLayers() {
        wantsLayer = true
        guard let rootLayer = layer else { return }

        displayLayer.contentsGravity = .resize
        displayLayer.frame = bounds
        rootLayer.addSublayer(displayLayer)

        cornerLayer.fillColor = nil
        cornerLayer.strokeColor = Self.cornerColor
        cornerLayer.lineWidth = Self.cornerLineWidth
        cornerLayer.lineCap = .round
        cornerLayer.shadowColor = NSColor.black.cgColor
        cornerLayer.shadowOffset = .zero
        cornerLayer.shadowRadius = 2
        cornerLayer.shadowOpacity = 0.6
        cornerLayer.frame = bounds
        cornerLayer.opacity = 1  // Visible initially
        rootLayer.addSublayer(cornerLayer)

        updateCornerPath()
    }

    private func observeConfiguration() {
        configuration.$mosaicType
            .sink { [weak self] _ in
                self?.reprocessCurrentFrame()
            }
            .store(in: &cancellables)

        configuration.$intensity
            .sink { [weak self] _ in
                self?.reprocessCurrentFrame()
            }
            .store(in: &cancellables)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.frame = bounds
        cornerLayer.frame = bounds
        updateCornerPath()
        CATransaction.commit()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isMouseInside = true
        if hasBeenMoved {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.15
                cornerLayer.opacity = 1
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        isMouseInside = false
        if hasBeenMoved {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                cornerLayer.opacity = 0
            }
        }
    }

    func windowDidMove() {
        guard !hasBeenMoved else { return }
        hasBeenMoved = true
        if !isMouseInside {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                cornerLayer.opacity = 0
            }
        }
    }

    private func updateCornerPath() {
        let path = CGMutablePath()
        let inset: CGFloat = 4
        let len = Self.cornerLength
        let r = bounds.insetBy(dx: inset, dy: inset)

        // Top-left
        path.move(to: CGPoint(x: r.minX, y: r.minY + len))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + len, y: r.minY))

        // Top-right
        path.move(to: CGPoint(x: r.maxX - len, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + len))

        // Bottom-right
        path.move(to: CGPoint(x: r.maxX, y: r.maxY - len))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.maxX - len, y: r.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: r.minX + len, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY - len))

        cornerLayer.path = path
    }

    // MARK: - Frame Processing

    func updateFrame(_ frame: CIImage) {
        currentFrame = frame
        processAndDisplay(frame)
    }

    private func reprocessCurrentFrame() {
        guard let frame = currentFrame else { return }
        processAndDisplay(frame)
    }

    private func processAndDisplay(_ frame: CIImage) {
        guard let filtered = filterProcessor.applyFilter(
            to: frame,
            type: configuration.mosaicType,
            intensity: configuration.intensity
        ) else { return }

        guard let cgImage = filterProcessor.render(filtered) else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        displayLayer.contents = cgImage
        CATransaction.commit()
    }

    // MARK: - Scroll Wheel Intensity Adjustment

    override func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 0.5 : 2.0)
        let range = configuration.mosaicType.intensityRange
        let newValue = min(max(configuration.intensity + delta, range.lowerBound), range.upperBound)
        configuration.intensity = newValue
    }

    // MARK: - Context Menu

    override func menu(for event: NSEvent) -> NSMenu? {
        OverlayContextMenu.build(for: configuration, window: window as? OverlayWindow)
    }
}
