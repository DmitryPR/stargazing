import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
if arguments.count != 3 || (arguments[1] != "true" && arguments[1] != "magnetic") {
    fputs("usage: photo-fixture.swift true|magnetic <jpeg>\n", stderr)
    exit(1)
}

let trueHeading = arguments[1] == "true"
let headingRef = trueHeading ? "T" : "M"
let heading = trueHeading ? 125.4344100197759 : 40.0

let output = URL(fileURLWithPath: arguments[2])
do {
    try FileManager.default.createDirectory(
        at: output.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
} catch {
    fputs("could not create the fixture directory\n", stderr)
    exit(1)
}

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
guard let context = CGContext(
    data: nil,
    width: 1,
    height: 1,
    bitsPerComponent: 8,
    bytesPerRow: 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("could not create the image\n", stderr)
    exit(1)
}

context.setFillColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 1)
context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
guard let image = context.makeImage() else {
    fputs("could not create the image\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(
    output as CFURL,
    UTType.jpeg.identifier as CFString,
    1,
    nil
) else {
    fputs("could not create the jpeg\n", stderr)
    exit(1)
}

let gps: [CFString: Any] = [
    kCGImagePropertyGPSLatitude: 59.35694166666666,
    kCGImagePropertyGPSLatitudeRef: "N",
    kCGImagePropertyGPSLongitude: 24.5237,
    kCGImagePropertyGPSLongitudeRef: "E",
    kCGImagePropertyGPSAltitude: 37.02728708889846,
    kCGImagePropertyGPSAltitudeRef: 0,
    kCGImagePropertyGPSDateStamp: "2026:11:14",
    kCGImagePropertyGPSTimeStamp: "05:17:31",
    kCGImagePropertyGPSImgDirection: heading,
    kCGImagePropertyGPSImgDirectionRef: headingRef,
]
let exif: [CFString: Any] = [
    kCGImagePropertyExifDateTimeOriginal: "2026:11:14 07:17:32",
    kCGImagePropertyExifLensModel: "fixture",
    kCGImagePropertyExifFocalLength: 9.0,
    kCGImagePropertyExifFocalLenIn35mmFilm: 95,
]
let properties: [CFString: Any] = [
    kCGImagePropertyGPSDictionary: gps,
    kCGImagePropertyExifDictionary: exif,
]

CGImageDestinationAddImage(destination, image, properties as CFDictionary)
if !CGImageDestinationFinalize(destination) {
    fputs("could not write the jpeg\n", stderr)
    exit(1)
}
