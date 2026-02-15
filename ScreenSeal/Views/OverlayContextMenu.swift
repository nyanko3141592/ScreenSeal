import AppKit

enum OverlayContextMenu {
    static func build(for configuration: OverlayConfiguration, window: OverlayWindow?) -> NSMenu {
        let menu = NSMenu()

        // Mosaic type submenu
        let typeItem = NSMenuItem(title: "Mosaic Type", action: nil, keyEquivalent: "")
        let typeMenu = NSMenu()
        for type in MosaicType.allCases {
            let item = NSMenuItem(title: type.rawValue, action: #selector(MenuActionTarget.selectMosaicType(_:)), keyEquivalent: "")
            item.representedObject = TypeSelection(type: type, configuration: configuration)
            item.target = MenuActionTarget.shared
            if configuration.mosaicType == type {
                item.state = .on
            }
            typeMenu.addItem(item)
        }
        typeItem.submenu = typeMenu
        menu.addItem(typeItem)

        menu.addItem(.separator())

        // Intensity slider
        let sliderItem = NSMenuItem()
        let sliderView = IntensitySliderView(configuration: configuration)
        sliderItem.view = sliderView
        menu.addItem(sliderItem)

        menu.addItem(.separator())

        // Lock/Unlock
        let lockTitle = configuration.isLocked ? "Unlock Position" : "Lock Position"
        let lockItem = NSMenuItem(title: lockTitle, action: #selector(MenuActionTarget.toggleLock(_:)), keyEquivalent: "")
        lockItem.representedObject = LockSelection(configuration: configuration, window: window)
        lockItem.target = MenuActionTarget.shared
        menu.addItem(lockItem)

        menu.addItem(.separator())

        // Close window
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(MenuActionTarget.closeWindow(_:)), keyEquivalent: "")
        closeItem.representedObject = window
        closeItem.target = MenuActionTarget.shared
        menu.addItem(closeItem)

        return menu
    }
}

// MARK: - Intensity Slider View

private final class IntensitySliderView: NSView {
    private let configuration: OverlayConfiguration
    private let slider: NSSlider
    private let label: NSTextField
    private let valueLabel: NSTextField

    init(configuration: OverlayConfiguration) {
        self.configuration = configuration

        let range = configuration.mosaicType.intensityRange

        label = NSTextField(labelWithString: "Intensity")
        label.font = .menuFont(ofSize: 13)

        valueLabel = NSTextField(labelWithString: String(format: "%.0f", configuration.intensity))
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        valueLabel.alignment = .right

        slider = NSSlider(value: configuration.intensity,
                         minValue: range.lowerBound,
                         maxValue: range.upperBound,
                         target: nil,
                         action: nil)
        slider.isContinuous = true

        super.init(frame: NSRect(x: 0, y: 0, width: 220, height: 50))

        slider.target = self
        slider.action = #selector(sliderChanged(_:))

        addSubview(label)
        addSubview(valueLabel)
        addSubview(slider)

        label.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),

            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            valueLabel.widthAnchor.constraint(equalToConstant: 40),

            slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let value = sender.doubleValue
        configuration.intensity = value
        valueLabel.stringValue = String(format: "%.0f", value)
    }
}

// MARK: - Selection Types

private final class TypeSelection: NSObject {
    let type: MosaicType
    let configuration: OverlayConfiguration
    init(type: MosaicType, configuration: OverlayConfiguration) {
        self.type = type
        self.configuration = configuration
    }
}

private final class LockSelection: NSObject {
    let configuration: OverlayConfiguration
    let window: OverlayWindow?
    init(configuration: OverlayConfiguration, window: OverlayWindow?) {
        self.configuration = configuration
        self.window = window
    }
}

// MARK: - Menu Action Target

private final class MenuActionTarget: NSObject {
    static let shared = MenuActionTarget()

    @objc func selectMosaicType(_ sender: NSMenuItem) {
        guard let selection = sender.representedObject as? TypeSelection else { return }
        selection.configuration.setMosaicType(selection.type)
    }

    @objc func toggleLock(_ sender: NSMenuItem) {
        guard let selection = sender.representedObject as? LockSelection else { return }
        let newLocked = !selection.configuration.isLocked
        selection.configuration.isLocked = newLocked
        if newLocked {
            selection.window?.lockPosition()
        } else {
            selection.window?.unlockPosition()
        }
    }

    @objc func closeWindow(_ sender: NSMenuItem) {
        guard let window = sender.representedObject as? OverlayWindow else { return }
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.windowManager.removeWindow(window)
    }
}
