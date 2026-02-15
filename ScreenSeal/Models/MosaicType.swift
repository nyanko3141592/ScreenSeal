import CoreImage

enum MosaicType: String, CaseIterable, Identifiable {
    case pixelation = "Pixelation"
    case gaussianBlur = "Gaussian Blur"
    case crystallize = "Crystallize"

    var id: String { rawValue }

    var filterName: String {
        switch self {
        case .pixelation: return "CIPixellate"
        case .gaussianBlur: return "CIGaussianBlur"
        case .crystallize: return "CICrystallize"
        }
    }

    var parameterKey: String {
        switch self {
        case .pixelation: return kCIInputScaleKey
        case .gaussianBlur: return kCIInputRadiusKey
        case .crystallize: return kCIInputRadiusKey
        }
    }

    var intensityRange: ClosedRange<Double> {
        switch self {
        case .pixelation: return 5...100
        case .gaussianBlur: return 5...50
        case .crystallize: return 5...100
        }
    }

    var defaultIntensity: Double {
        switch self {
        case .pixelation: return 20
        case .gaussianBlur: return 15
        case .crystallize: return 20
        }
    }
}
