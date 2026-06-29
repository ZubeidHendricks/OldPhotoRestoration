import XCTest
import UIKit
// RestoreService.swift compiled into this test target.

final class RestoreTests: XCTestCase {
    private func image(_ s: CGFloat = 400) -> UIImage {
        let f = UIGraphicsImageRendererFormat.default(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: s, height: s), format: f).image { c in
            UIColor.darkGray.setFill(); c.fill(CGRect(x: 0, y: 0, width: s, height: s))
        }
    }

    func testRestoreProducesImage() async throws {
        let out = try await OnDeviceRestoreService().restore(from: image(), colorize: false)
        XCTAssertEqual(out.cgImage?.width, image().cgImage?.width)
    }

    func testColorizePathProducesImage() async throws {
        let out = try await OnDeviceRestoreService().restore(from: image(), colorize: true)
        XCTAssertNotNil(out.cgImage)
    }
}
