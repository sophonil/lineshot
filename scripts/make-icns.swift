// Package the PNG icon representations into an ICNS file without iconutil.
// Usage: swift scripts/make-icns.swift iconset-directory out.icns
import Foundation
let folder = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
func length(_ value: Int) -> Data {
    var bigEndian = UInt32(value).bigEndian
    return withUnsafeBytes(of: &bigEndian) { Data($0) }
}
var body = Data()
for (tag, name) in [("ic07", "icon_128x128.png"), ("ic08", "icon_256x256.png"),
                    ("ic09", "icon_512x512.png"), ("ic10", "icon_512x512@2x.png")] {
    let png = try Data(contentsOf: folder.appendingPathComponent(name))
    guard png.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]) else {
        fatalError("Invalid PNG: \(name)")
    }
    body.append(Data(tag.utf8))
    body.append(length(png.count + 8))
    body.append(png)
}
var icon = Data("icns".utf8)
icon.append(length(body.count + 8))
icon.append(body)
try icon.write(to: output)
