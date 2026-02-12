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

        // Intensity submenu
        let intensityItem = NSMenuItem(title: "Intensity", action: nil, keyEquivalent: "")
        let intensityMenu = NSMenu()
        let range = configuration.mosaicType.intensityRange
        let step = (range.upperBound - range.lowerBound) / 4
        for i in 0...4 {
            let value = range.lowerBound + step * Double(i)
            let label = String(format: "%.0f", value)
            let item = NSMenuItem(title: label, action: #selector(MenuActionTarget.selectIntensity(_:)), keyEquivalent: "")
            item.representedObject = IntensitySelection(value: value, configuration: configuration)
            item.target = MenuActionTarget.shared
            if abs(configuration.intensity - value) < step / 2 {
                item.state = .on
            }
            intensityMenu.addItem(item)
        }
        intensityItem.submenu = intensityMenu
        menu.addItem(intensityItem)

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

// MARK: - Selection Types

private final class TypeSelection: NSObject {
    let type: MosaicType
    let configuration: OverlayConfiguration
    init(type: MosaicType, configuration: OverlayConfiguration) {
        self.type = type
        self.configuration = configuration
    }
}

private final class IntensitySelection: NSObject {
    let value: Double
    let configuration: OverlayConfiguration
    init(value: Double, configuration: OverlayConfiguration) {
        self.value = value
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

    @objc func selectIntensity(_ sender: NSMenuItem) {
        guard let selection = sender.representedObject as? IntensitySelection else { return }
        selection.configuration.intensity = selection.value
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
        // Find the window manager via the app delegate
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.windowManager.removeWindow(window)
    }
}
