import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum RestoreError: Error { case badImage, notConfigured }

protocol RestoreService {
    func restore(from image: UIImage, colorize: Bool) async throws -> UIImage
}

/// Fully on-device restoration: noise reduction + luminance sharpening + Core
/// Image's auto-adjustments (exposure/contrast/tone) — the workhorse pipeline
/// for faded, soft, noisy old scans. Generative colorization/upscaling goes
/// behind `RemoteRestoreService`.
struct OnDeviceRestoreService: RestoreService {
    private let context = CIContext()

    func restore(from image: UIImage, colorize: Bool) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try Self.render(image: image, colorize: colorize, context: context)
        }.value
    }

    private static func render(image: UIImage, colorize: Bool, context: CIContext) throws -> UIImage {
        guard let cg = image.normalizedUp().cgImage else { throw RestoreError.badImage }
        var ci = CIImage(cgImage: cg)
        let extent = ci.extent

        // Noise reduction.
        let nr = CIFilter.noiseReduction()
        nr.inputImage = ci
        nr.noiseLevel = 0.02
        nr.sharpness = 0.4
        ci = nr.outputImage ?? ci

        // Luminance sharpening to recover soft detail.
        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = ci
        sharpen.sharpness = 0.5
        ci = sharpen.outputImage ?? ci

        // Apply Core Image's auto enhancement (exposure, contrast, tone curve).
        for filter in ci.autoAdjustmentFilters(options: [.redEye: false]) {
            filter.setValue(ci, forKey: kCIInputImageKey)
            ci = filter.outputImage ?? ci
        }

        // Gentle warm tone when "colorize" is on (true generative colorization is
        // a Remote-service upgrade; this is an honest on-device tint).
        if colorize {
            let temp = CIFilter.temperatureAndTint()
            temp.inputImage = ci
            temp.neutral = CIVector(x: 6500, y: 0)
            temp.targetNeutral = CIVector(x: 5200, y: 10)
            ci = temp.outputImage ?? ci
        }

        ci = ci.cropped(to: extent)
        guard let result = context.createCGImage(ci, from: extent) else { throw RestoreError.badImage }
        return UIImage(cgImage: result)
    }
}

struct RemoteRestoreService: RestoreService {
    let apiKey: String
    func restore(from image: UIImage, colorize: Bool) async throws -> UIImage {
        throw RestoreError.notConfigured
    }
}

extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
