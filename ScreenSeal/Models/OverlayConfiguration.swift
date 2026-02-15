import Foundation
import Combine

final class OverlayConfiguration: ObservableObject {
    @Published var mosaicType: MosaicType {
        didSet { Self.saveDefaults(type: mosaicType, intensity: intensity) }
    }
    @Published var intensity: Double {
        didSet { Self.saveDefaults(type: mosaicType, intensity: intensity) }
    }
    @Published var isLocked: Bool = false

    init() {
        let saved = Self.loadDefaults()
        self.mosaicType = saved.type
        self.intensity = saved.intensity
    }

    func setMosaicType(_ type: MosaicType) {
        mosaicType = type
        intensity = type.defaultIntensity
    }

    // MARK: - Persistence

    private static let typeKey = "ScreenSeal.lastMosaicType"
    private static let intensityKey = "ScreenSeal.lastIntensity"

    private static func saveDefaults(type: MosaicType, intensity: Double) {
        UserDefaults.standard.set(type.rawValue, forKey: typeKey)
        UserDefaults.standard.set(intensity, forKey: intensityKey)
    }

    private static func loadDefaults() -> (type: MosaicType, intensity: Double) {
        let typeRaw = UserDefaults.standard.string(forKey: typeKey) ?? ""
        let type = MosaicType(rawValue: typeRaw) ?? .pixelation
        let intensity = UserDefaults.standard.double(forKey: intensityKey)
        let finalIntensity = intensity > 0 ? intensity : type.defaultIntensity
        return (type, finalIntensity)
    }
}
