import AppKit

guard CommandLine.arguments.count == 4 else {
    fatalError("usage: compare source implementation output")
}

let targetSize = NSSize(width: 688, height: 328)
let canvas = NSImage(size: NSSize(width: targetSize.width * 2, height: targetSize.height))

guard
    let source = NSImage(contentsOfFile: CommandLine.arguments[1]),
    let implementation = NSImage(contentsOfFile: CommandLine.arguments[2])
else {
    fatalError("unable to load comparison images")
}

canvas.lockFocus()
NSColor.black.setFill()
NSRect(origin: .zero, size: canvas.size).fill()
source.draw(in: NSRect(origin: .zero, size: targetSize))
implementation.draw(in: NSRect(
    x: targetSize.width,
    y: 0,
    width: targetSize.width,
    height: targetSize.height
))
canvas.unlockFocus()

guard
    let tiff = canvas.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("unable to encode comparison")
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
