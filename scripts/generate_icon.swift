import AppKit

func generateIcon(size: Double) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    let text = "🍵" as NSString
    let fontSize = size * 0.9 // Emoji takes up most of the space
    let font = NSFont.systemFont(ofSize: fontSize)
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font
    ]
    
    let stringSize = text.size(withAttributes: attributes)
    let point = NSPoint(x: (size - stringSize.width) / 2, y: (size - stringSize.height) / 2)
    
    text.draw(at: point, withAttributes: attributes)
    
    image.unlockFocus()
    return image
}

let fileManager = FileManager.default
let iconsetPath = "AppIcon.iconset"

do {
    if fileManager.fileExists(atPath: iconsetPath) {
        try fileManager.removeItem(atPath: iconsetPath)
    }
    try fileManager.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("Error creating directory: \(error)")
    exit(1)
}

let sizes = [16, 32, 128, 256, 512]

for size in sizes {
    // Normal resolution
    let image = generateIcon(size: Double(size))
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filename = "icon_\(size)x\(size).png"
        let url = URL(fileURLWithPath: iconsetPath).appendingPathComponent(filename)
        try? pngData.write(to: url)
    }
    
    // Retina resolution (2x)
    let retinaSize = size * 2
    let retinaImage = generateIcon(size: Double(retinaSize))
    if let tiffData = retinaImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filename = "icon_\(size)x\(size)@2x.png"
        let url = URL(fileURLWithPath: iconsetPath).appendingPathComponent(filename)
        try? pngData.write(to: url)
    }
}

print("✅ Generated .iconset images")

// Convert to icns
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]

try? process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("✅ Created AppIcon.icns")
    // Clean up
    try? fileManager.removeItem(atPath: iconsetPath)
} else {
    print("❌ Failed to create icns")
    exit(1)
}
