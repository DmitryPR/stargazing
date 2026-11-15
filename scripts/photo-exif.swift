import Foundation
import ImageIO

let arguments = CommandLine.arguments
if arguments.count != 3 {
    fputs("usage: photo-exif.swift <photo> <output>\n", stderr)
    exit(1)
}

let photoURL = URL(fileURLWithPath: arguments[1]) as CFURL
guard let source = CGImageSourceCreateWithURL(photoURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
    fputs("could not read image metadata\n", stderr)
    exit(1)
}

let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] ?? [:]
let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]

func text(_ value: Any?) -> String {
    guard let value else { return "" }
    if let item = value as? String { return item.trimmingCharacters(in: .whitespaces) }
    if let item = value as? NSNumber { return item.stringValue }
    return String(describing: value).trimmingCharacters(in: .whitespaces)
}

func number(_ value: Any?) -> Double? {
    if let item = value as? Double { return item }
    if let item = value as? NSNumber { return item.doubleValue }
    if let item = value as? String { return Double(item) }
    return nil
}

func signed(_ value: Any?, negativeRefs: Set<String>) -> Double? {
    guard let magnitude = number(value) else { return nil }
    return negativeRefs.contains(text(gps[kCGImagePropertyGPSLatitudeRef]).uppercased()) ? -abs(magnitude) : abs(magnitude)
}

func clockParts(_ value: Any?) -> (Int, Int, Double)? {
    if let parts = value as? [Any], parts.count >= 3,
       let hour = number(parts[0]), let minute = number(parts[1]), let second = number(parts[2]) {
        return (Int(hour), Int(minute), second)
    }
    let raw = text(value)
    let pieces = raw.split(separator: ":")
    guard pieces.count >= 3,
          let hour = Int(pieces[0]), let minute = Int(pieces[1]), let second = Double(pieces[2]) else {
        return nil
    }
    return (hour, minute, second)
}

func clockText(_ parts: (Int, Int, Double)) -> String {
    let whole = Int(parts.2)
    let fraction = parts.2 - Double(whole)
    if fraction > 0.0000001 {
        return String(format: "%02d:%02d:%06.3f", parts.0, parts.1, parts.2)
    }
    return String(format: "%02d:%02d:%02d", parts.0, parts.1, whole)
}

func dateText(_ value: Any?) -> String {
    let raw = text(value)
    guard raw.count >= 10 else { return raw.replacingOccurrences(of: " ", with: "T") }
    let dateEnd = raw.index(raw.startIndex, offsetBy: 10)
    let date = raw[..<dateEnd].replacingOccurrences(of: ":", with: "-")
    let remainder = raw[dateEnd...].replacingOccurrences(of: " ", with: "T")
    return date + remainder
}

let latitude = signed(gps[kCGImagePropertyGPSLatitude], negativeRefs: ["S"])
let longitudeRef = text(gps[kCGImagePropertyGPSLongitudeRef]).uppercased()
let longitudeMagnitude = number(gps[kCGImagePropertyGPSLongitude])
let longitude = longitudeMagnitude.map { longitudeRef == "W" ? -abs($0) : abs($0) }
let altitudeMagnitude = number(gps[kCGImagePropertyGPSAltitude])
let altitude = altitudeMagnitude.map { text(gps[kCGImagePropertyGPSAltitudeRef]) == "1" ? -abs($0) : abs($0) }
let heading = number(gps[kCGImagePropertyGPSImgDirection])
let headingRef = text(gps[kCGImagePropertyGPSImgDirectionRef]).uppercased()

let local = dateText(exif[kCGImagePropertyExifDateTimeOriginal])
var utc = ""
if let parts = clockParts(gps[kCGImagePropertyGPSTimeStamp]) {
    let day = text(gps[kCGImagePropertyGPSDateStamp]).replacingOccurrences(of: ":", with: "-")
    if day.count == 10 {
        utc = "\(day)T\(clockText(parts))Z"
    }
}

func quote(_ value: String) -> String {
    "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

func shown(_ value: String, suffix: String = "") -> String {
    value.isEmpty ? "(none)" : value + suffix
}

func decimal(_ value: Double?) -> String {
    guard let value else { return "" }
    return String(value)
}

let lens = text(exif[kCGImagePropertyExifLensModel])
let focal = decimal(number(exif[kCGImagePropertyExifFocalLength]))
let focal35 = decimal(number(exif[kCGImagePropertyExifFocalLenIn35mmFilm]))
let latitudeText = latitude.map { String($0) } ?? ""
let longitudeText = longitude.map { String($0) } ?? ""
let altitudeText = altitude.map { String($0) } ?? ""
let headingText = heading.map { String($0) } ?? ""

let body = """
---
stage: photo
status: review
path: \(quote(arguments[1]))
local: \(quote(local))
utc: \(quote(utc))
latitude: \(latitudeText.isEmpty ? "\"\"" : latitudeText)
longitude: \(longitudeText.isEmpty ? "\"\"" : longitudeText)
altitude: \(altitudeText.isEmpty ? "\"\"" : altitudeText)
heading: \(headingText.isEmpty ? "\"\"" : headingText)
heading_ref: \(quote(headingRef))
focal_mm: \(focal.isEmpty ? "\"\"" : focal)
focal_35mm: \(focal35.isEmpty ? "\"\"" : focal35)
lens: \(quote(lens))
---

Photograph:

- Path: \(arguments[1])
- Local clock: \(shown(local))
- GPS instant: \(shown(utc))
- Latitude: \(shown(latitudeText, suffix: "°"))
- Longitude: \(shown(longitudeText, suffix: "°"))
- Altitude: \(shown(altitudeText, suffix: " m"))
- Heading: \(shown(headingText, suffix: "°"))
- Heading reference: \(shown(headingRef))
- Focal length: \(shown(focal, suffix: " mm"))
- 35 mm equivalent: \(shown(focal35, suffix: " mm"))
- Lens: \(shown(lens))

A heading reference of T is true north. A heading reference of M is magnetic and is not converted. The person accepts a field before it is sent to Stellarium. This file stays in output/.
"""

do {
    try body.write(to: URL(fileURLWithPath: arguments[2]), atomically: true, encoding: String.Encoding.utf8)
} catch {
    fputs("could not write the photo record\n", stderr)
    exit(1)
}
