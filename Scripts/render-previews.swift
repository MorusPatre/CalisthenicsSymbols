// Renders the README previews in docs/ through the system's symbol renderer,
// so they show the symbols exactly as an app draws them.
//
// Run from the repository root:
//
//     swift Scripts/render-previews.swift

import AppKit

let symbols = [
    "figure.pullup", "figure.chinup", "figure.deadhang",
    "figure.invertedrow", "figure.pushup", "figure.pikepushup",
    "figure.dip", "figure.squat", "figure.pistolsquat",
]

let weights: [(name: String, weight: NSFont.Weight)] = [
    ("Ultralight", .ultraLight), ("Thin", .thin), ("Light", .light),
    ("Regular", .regular), ("Medium", .medium), ("Semibold", .semibold),
    ("Bold", .bold), ("Heavy", .heavy), ("Black", .black),
]

struct Theme {
    let name: String
    let primary: NSColor
    let secondary: NSColor
}

let themes = [
    Theme(
        name: "light",
        primary: NSColor(srgbRed: 0.114, green: 0.114, blue: 0.122, alpha: 1),
        secondary: NSColor(srgbRed: 0.431, green: 0.431, blue: 0.451, alpha: 1)
    ),
    Theme(
        name: "dark",
        primary: NSColor(srgbRed: 0.961, green: 0.961, blue: 0.969, alpha: 1),
        secondary: NSColor(srgbRed: 0.596, green: 0.596, blue: 0.616, alpha: 1)
    ),
]

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let catalog = root.appendingPathComponent("Sources/CalisthenicsSymbols/Resources/Symbols.xcassets")
let docs = root.appendingPathComponent("docs")

// Every symbol set in the catalog has to be drawn.
let symbolSets = try fileManager.contentsOfDirectory(atPath: catalog.path)
    .filter { $0.hasSuffix(".symbolset") }
    .map { String($0.dropLast(".symbolset".count)) }
guard Set(symbolSets) == Set(symbols) else {
    fatalError("The symbol list doesn't match the asset catalog: \(symbolSets.sorted())")
}

// Compile the catalog into a bundle and load the symbols from it.
let work = fileManager.temporaryDirectory.appendingPathComponent("CalisthenicsSymbols-\(UUID().uuidString)")
let bundleURL = work.appendingPathComponent("Symbols.bundle")
let resources = bundleURL.appendingPathComponent("Contents/Resources")
try fileManager.createDirectory(at: resources, withIntermediateDirectories: true)

let actool = Process()
actool.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
actool.arguments = [
    "actool", catalog.path,
    "--compile", resources.path,
    "--platform", "macosx",
    "--minimum-deployment-target", "13.0",
    "--output-partial-info-plist", work.appendingPathComponent("partial.plist").path,
]
actool.standardOutput = FileHandle.nullDevice
try actool.run()
actool.waitUntilExit()
guard actool.terminationStatus == 0 else { fatalError("actool failed") }

let info: NSDictionary = ["CFBundleIdentifier": "preview.CalisthenicsSymbols", "CFBundlePackageType": "BNDL"]
info.write(to: bundleURL.appendingPathComponent("Contents/Info.plist"), atomically: true)
guard let bundle = Bundle(url: bundleURL) else { fatalError("Couldn't open \(bundleURL.path)") }

func symbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSImage {
    let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    guard let image = NSImage(symbolName: name, bundle: bundle, variableValue: 1)?
        .withSymbolConfiguration(configuration)
    else { fatalError("Couldn't load \(name)") }
    return image
}

/// Draws a transparent PNG at 2x. `draw` gets the canvas height so it can
/// place things from the top.
func writePNG(named name: String, size: CGSize, draw: (CGFloat) -> Void) throws {
    let scale: CGFloat = 2
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("Couldn't make a bitmap") }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(size.height)
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("Couldn't encode \(name)") }
    try data.write(to: docs.appendingPathComponent(name))
    print("Wrote docs/\(name)")
}

/// Draws `image` centred in `rect`, where `rect` is measured from the top.
func draw(_ image: NSImage, centredIn rect: CGRect, canvasHeight: CGFloat) {
    let origin = CGPoint(
        x: (rect.midX - image.size.width / 2).rounded(),
        y: (canvasHeight - rect.midY - image.size.height / 2).rounded()
    )
    image.draw(in: CGRect(origin: origin, size: image.size))
}

/// Draws `text` centred horizontally on `x`, with its top at `top`.
func draw(_ text: String, font: NSFont, color: NSColor, centredOn x: CGFloat, top: CGFloat, canvasHeight: CGFloat) {
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    let size = string.size()
    string.draw(at: CGPoint(x: x - size.width / 2, y: canvasHeight - top - size.height))
}

try fileManager.createDirectory(at: docs, withIntermediateDirectories: true)

for theme in themes {
    // All nine symbols at Regular, three to a row, with their names.
    do {
        let pointSize: CGFloat = 64
        let images = symbols.map { symbol($0, pointSize: pointSize, weight: .regular, color: theme.primary) }
        let glyphHeight = images.map(\.size.height).max()!
        let columns = 3
        let cellWidth: CGFloat = 280
        let cellHeight = (glyphHeight + 80).rounded()
        let rows = (symbols.count + columns - 1) / columns
        let size = CGSize(width: cellWidth * CGFloat(columns), height: cellHeight * CGFloat(rows))
        let font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)

        try writePNG(named: "symbols-\(theme.name).png", size: size) { height in
            for (index, image) in images.enumerated() {
                let x = cellWidth * CGFloat(index % columns)
                let y = cellHeight * CGFloat(index / columns)
                let glyphArea = CGRect(x: x, y: y + 16, width: cellWidth, height: glyphHeight)
                draw(image, centredIn: glyphArea, canvasHeight: height)
                draw(symbols[index], font: font, color: theme.secondary,
                     centredOn: glyphArea.midX, top: glyphArea.maxY + 18, canvasHeight: height)
            }
        }
    }

    // Every symbol at all nine weights.
    do {
        let pointSize: CGFloat = 36
        let images = symbols.map { name in
            weights.map { symbol(name, pointSize: pointSize, weight: $0.weight, color: theme.primary) }
        }
        let rowHeight = (images.flatMap { $0.map(\.size.height) }.max()! + 22).rounded()
        let columnWidth: CGFloat = 100
        let headerHeight: CGFloat = 36
        let size = CGSize(
            width: columnWidth * CGFloat(weights.count),
            height: headerHeight + rowHeight * CGFloat(symbols.count) + 8
        )
        let font = NSFont.systemFont(ofSize: 13, weight: .medium)

        try writePNG(named: "weights-\(theme.name).png", size: size) { height in
            for (column, weight) in weights.enumerated() {
                let x = columnWidth * (CGFloat(column) + 0.5)
                draw(weight.name, font: font, color: theme.secondary, centredOn: x, top: 8, canvasHeight: height)
                for row in symbols.indices {
                    let cell = CGRect(
                        x: columnWidth * CGFloat(column), y: headerHeight + rowHeight * CGFloat(row),
                        width: columnWidth, height: rowHeight
                    )
                    draw(images[row][column], centredIn: cell, canvasHeight: height)
                }
            }
        }
    }
}

try? fileManager.removeItem(at: work)
