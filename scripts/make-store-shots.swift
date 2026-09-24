// Composites App Store screenshots: a captured screen sits in a drawn device
// body on a coloured field, under a short caption.
//
// Apple requires the screen itself to be the real app, so captures are drawn
// untouched and only the surround is generated here.
//
//   xcrun swift make-store-shots.swift shots.json <captures-dir> <output-dir>
//
// See templates/store-shots.json for the configuration shape.

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Configuration: Decodable {
    struct Size: Decodable {
        let width: Double
        let height: Double
    }

    struct Palette: Decodable {
        let gradientTop: String
        let gradientBottom: String
        let accent: String
        let caption: String
        let bezel: String
    }

    struct Shot: Decodable {
        let capture: String
        let output: String
        let caption: String
    }

    let canvas: Size
    let palette: Palette
    let fontPath: String
    let captionSize: Double
    let deviceWidthFraction: Double
    let shots: [Shot]
}

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    FileHandle.standardError.write(Data("usage: make-store-shots.swift <config.json> <captures-dir> <output-dir>\n".utf8))
    exit(2)
}
let configURL = URL(fileURLWithPath: arguments[1])
let capturesDirectory = URL(fileURLWithPath: arguments[2])
let outputDirectory = URL(fileURLWithPath: arguments[3])

guard let configData = try? Data(contentsOf: configURL),
      let config = try? JSONDecoder().decode(Configuration.self, from: configData) else {
    FileHandle.standardError.write(Data("could not read \(configURL.path)\n".utf8))
    exit(1)
}

let canvas = CGSize(width: config.canvas.width, height: config.canvas.height)

func color(_ hex: String) -> CGColor {
    var value = hex
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let number = UInt32(value, radix: 16) else {
        FileHandle.standardError.write(Data("bad colour \(hex), expected #RRGGBB\n".utf8))
        exit(1)
    }
    return CGColor(
        srgbRed: Double((number >> 16) & 0xFF) / 255,
        green: Double((number >> 8) & 0xFF) / 255,
        blue: Double(number & 0xFF) / 255,
        alpha: 1
    )
}

let gradientTop = color(config.palette.gradientTop)
let gradientBottom = color(config.palette.gradientBottom)
let accent = color(config.palette.accent)
let captionColor = color(config.palette.caption)
let bezelColor = color(config.palette.bezel)

func loadFont(size: CGFloat) -> CTFont {
    let url = configURL.deletingLastPathComponent().appendingPathComponent(config.fontPath)
    guard let provider = CGDataProvider(url: url as CFURL), let font = CGFont(provider) else {
        FileHandle.standardError.write(Data("could not load font at \(url.path)\n".utf8))
        exit(1)
    }
    return CTFontCreateWithGraphicsFont(font, size, nil, nil)
}

func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        FileHandle.standardError.write(Data("could not read \(url.path)\n".utf8))
        exit(1)
    }
    return image
}

func drawBackground(in context: CGContext) {
    let space = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(
        colorsSpace: space,
        colors: [gradientTop, gradientBottom] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: canvas.width * 0.15, y: canvas.height),
        end: CGPoint(x: canvas.width * 0.85, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    // A half court, drawn faintly behind everything, so the field reads as a
    // court rather than a plain gradient.
    context.saveGState()
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.05))
    context.setLineWidth(6)
    let inset: CGFloat = 96
    let court = CGRect(x: inset, y: inset, width: canvas.width - inset * 2, height: canvas.height - inset * 2)
    context.stroke(court)
    context.move(to: CGPoint(x: court.minX, y: court.midY))
    context.addLine(to: CGPoint(x: court.maxX, y: court.midY))
    context.move(to: CGPoint(x: court.midX, y: court.minY))
    context.addLine(to: CGPoint(x: court.midX, y: court.minY + court.height * 0.28))
    context.move(to: CGPoint(x: court.midX, y: court.maxY))
    context.addLine(to: CGPoint(x: court.midX, y: court.maxY - court.height * 0.28))
    context.strokePath()
    context.restoreGState()
}

func drawCaption(_ caption: String, in context: CGContext) {
    let font = loadFont(size: config.captionSize)
    var alignment = CTTextAlignment.center
    var lineSpacing: CGFloat = 12
    let settings = withUnsafeBytes(of: &alignment) { alignmentBytes in
        withUnsafeBytes(of: &lineSpacing) { spacingBytes in
            [
                CTParagraphStyleSetting(
                    spec: .alignment,
                    valueSize: MemoryLayout<CTTextAlignment>.size,
                    value: alignmentBytes.baseAddress!
                ),
                CTParagraphStyleSetting(
                    spec: .lineSpacingAdjustment,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: spacingBytes.baseAddress!
                ),
            ]
        }
    }
    let paragraph = CTParagraphStyleCreate(settings, settings.count)

    let attributed = NSAttributedString(string: caption, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): captionColor,
        NSAttributedString.Key(kCTKernAttributeName as String): -1.6,
        NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraph,
    ])
    let framesetter = CTFramesetterCreateWithAttributedString(attributed)
    let width = canvas.width - 150 * 2
    let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
        framesetter, CFRange(), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil
    )
    let top = canvas.height - 250
    let rect = CGRect(x: 150, y: top - suggested.height, width: width, height: suggested.height)
    let frame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: rect, transform: nil), nil)
    CTFrameDraw(frame, context)

    // The rule is anchored to a fixed height rather than to the caption's own
    // box, so a one-line caption does not shift it out of line with the rest
    // of the set.
    let ruleWidth: CGFloat = 132
    context.setFillColor(accent)
    let rule = CGRect(x: (canvas.width - ruleWidth) / 2, y: top - 268, width: ruleWidth, height: 10)
    context.addPath(CGPath(roundedRect: rule, cornerWidth: 5, cornerHeight: 5, transform: nil))
    context.fillPath()
}

func drawDevice(_ screen: CGImage, in context: CGContext) {
    let aspect = CGFloat(screen.height) / CGFloat(screen.width)
    let screenWidth = canvas.width * config.deviceWidthFraction
    let screenHeight = screenWidth * aspect
    let centreY = screenHeight / 2 + 250
    let screenRect = CGRect(
        x: (canvas.width - screenWidth) / 2,
        y: centreY - screenHeight / 2,
        width: screenWidth,
        height: screenHeight
    )

    let bezelWidth: CGFloat = 16
    let body = screenRect.insetBy(dx: -bezelWidth, dy: -bezelWidth)
    let bodyRadius: CGFloat = 96
    let bodyPath = CGPath(roundedRect: body, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -28), blur: 64,
                      color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45))
    context.setFillColor(bezelColor)
    context.addPath(bodyPath)
    context.fillPath()
    context.restoreGState()

    let screenRadius = bodyRadius - bezelWidth
    context.saveGState()
    context.addPath(CGPath(roundedRect: screenRect, cornerWidth: screenRadius, cornerHeight: screenRadius, transform: nil))
    context.clip()
    context.draw(screen, in: screenRect)
    context.restoreGState()

    // A hairline catches the light the way a real edge does, so the body does
    // not read as a flat black rectangle against a dark field.
    context.saveGState()
    context.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.16))
    context.setLineWidth(3)
    context.addPath(bodyPath)
    context.strokePath()
    context.restoreGState()
}

func write(_ image: CGImage, to url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil
    ) else {
        fatalError("Could not create \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(url.path)")
    }
}

try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for shot in config.shots {
    let screen = loadImage(capturesDirectory.appendingPathComponent(shot.capture))
    guard let context = CGContext(
        data: nil,
        width: Int(canvas.width),
        height: Int(canvas.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create the drawing context")
    }

    drawBackground(in: context)
    drawCaption(shot.caption, in: context)
    drawDevice(screen, in: context)

    guard let image = context.makeImage() else { fatalError("Could not render \(shot.output)") }
    let url = outputDirectory.appendingPathComponent(shot.output)
    write(image, to: url)
    print("\(shot.output)  \(image.width)x\(image.height)")
}
