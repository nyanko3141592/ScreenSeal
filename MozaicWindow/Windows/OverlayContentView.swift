import AppKit
import Combine
import CoreImage

final class OverlayContentView: NSView {
    private let configuration: OverlayConfiguration
    private let filterProcessor = FilterProcessor()
    private let displayLayer = CALayer()
    private let borderLayer = CAShapeLayer()
    private var cancellables = Set<AnyCancellable>()
    private var currentFrame: CIImage?

    private static let borderColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
    private static let borderWidth: CGFloat = 2.0

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

        borderLayer.fillColor = nil
        borderLayer.strokeColor = Self.borderColor
        borderLayer.lineWidth = Self.borderWidth
        borderLayer.frame = bounds
        rootLayer.addSublayer(borderLayer)

        updateBorderPath()
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
        borderLayer.frame = bounds
        updateBorderPath()
        CATransaction.commit()
    }

    private func updateBorderPath() {
        let inset = Self.borderWidth / 2
        let rect = bounds.insetBy(dx: inset, dy: inset)
        borderLayer.path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
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

    // MARK: - Context Menu

    override func menu(for event: NSEvent) -> NSMenu? {
        OverlayContextMenu.build(for: configuration, window: window as? OverlayWindow)
    }
}
