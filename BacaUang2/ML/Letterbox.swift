//
//  Letterbox.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//

import CoreGraphics
import CoreVideo

enum Letterbox {
    static let fill: (r: CGFloat, g: CGFloat, b: CGFloat) = (114.0 / 255.0, 114.0 / 255.0, 114.0 / 255.0)

    static func pixelBuffer(from cgImage: CGImage, size: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, size, size,
                                         kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: size, height: size,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.setFillColor(red: fill.r, green: fill.g, blue: fill.b, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))

        let scale = CGFloat(size) / max(CGFloat(cgImage.width), CGFloat(cgImage.height))
        let newW = CGFloat(cgImage.width) * scale
        let newH = CGFloat(cgImage.height) * scale
        let rect = CGRect(x: (CGFloat(size) - newW) / 2, y: (CGFloat(size) - newH) / 2, width: newW, height: newH)
        context.draw(cgImage, in: rect)

        return buffer
    }
}
