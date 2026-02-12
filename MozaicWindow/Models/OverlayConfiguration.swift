import Foundation
import Combine

final class OverlayConfiguration: ObservableObject {
    @Published var mosaicType: MosaicType = .pixelation
    @Published var intensity: Double = MosaicType.pixelation.defaultIntensity
    @Published var isLocked: Bool = false

    func setMosaicType(_ type: MosaicType) {
        mosaicType = type
        intensity = type.defaultIntensity
    }
}
