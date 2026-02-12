import CoreImage

final class FilterProcessor {
    private let context: CIContext

    init() {
        context = CIContext(options: [.useSoftwareRenderer: false])
    }

    func applyFilter(to image: CIImage, type: MosaicType, intensity: Double) -> CIImage? {
        let extent = image.extent

        guard let filter = CIFilter(name: type.filterName) else { return nil }

        switch type {
        case .gaussianBlur:
            // Clamp to prevent dark edges
            let clamped = image.clampedToExtent()
            filter.setValue(clamped, forKey: kCIInputImageKey)
            filter.setValue(intensity, forKey: type.parameterKey)
            return filter.outputImage?.cropped(to: extent)

        case .pixelation:
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(intensity, forKey: type.parameterKey)
            filter.setValue(CIVector(x: extent.midX, y: extent.midY), forKey: kCIInputCenterKey)
            return filter.outputImage?.cropped(to: extent)

        case .crystallize:
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(intensity, forKey: type.parameterKey)
            filter.setValue(CIVector(x: extent.midX, y: extent.midY), forKey: kCIInputCenterKey)
            return filter.outputImage?.cropped(to: extent)
        }
    }

    func render(_ image: CIImage) -> CGImage? {
        context.createCGImage(image, from: image.extent)
    }
}
