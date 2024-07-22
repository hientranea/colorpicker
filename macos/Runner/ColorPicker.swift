import Cocoa
import FlutterMacOS

@objc class ColorPicker: NSObject {
    private var isTracking = false
    private var trackingTimer: Timer?
    private var flutterResult: FlutterResult?
    private var lastColor: NSColor?

    @objc func startColorPicking(result: @escaping FlutterResult) {
        isTracking = true
        flutterResult = result
        startTracking()
    }

    @objc func getMagnifiedImage(x: CGFloat, y: CGFloat, result: @escaping FlutterResult) {
        guard let mainScreen = NSScreen.main else {
          assertionFailure()
          return
        }
        let size: CGFloat = 13 // Size of the magnified area
        let flippedY = mainScreen.frame.height - y
        if let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: x, y: flippedY), $0.frame, false) }) {
            let rectX = max(0, min(x - size/2, screenWithMouse.frame.width - size))
            let rectY = max(0, min(flippedY - size/2, screenWithMouse.frame.height - size))

            let rect = CGRect(x: rectX, y: rectY, width: size, height: size)

            let image = CGWindowListCreateImage(
                rect,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            )

            if let image = image {
                let nsImage = NSImage(cgImage: image, size: NSSize(width: size, height: size))
                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    result(FlutterStandardTypedData(bytes: pngData))
                } else {
                    result(FlutterError(code: "FAILED", message: "Failed to create image data", details: nil))
                }
            } else {
                result(FlutterError(code: "FAILED", message: "Failed to capture screen", details: nil))
            }
        } else {
            result(FlutterError(code: "FAILED", message: "Screen not found", details: nil))
        }
    }

    @objc func saveCurrentColor() {
        if let color = lastColor {
            let red = Int(color.redComponent * 255)
            let green = Int(color.greenComponent * 255)
            let blue = Int(color.blueComponent * 255)
            NotificationCenter.default.post(name: NSNotification.Name("ColorSaved"), object: nil, userInfo: [
                "color": [red, green, blue]
            ])
        }
    }

    private func startTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateColorAtMousePosition()}
    }

    private func updateColorAtMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        if let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }),
           let color = getColorAtPosition(mouseLocation, on: screenWithMouse) {
           lastColor = color

            let red = Int(color.redComponent * 255)
            let green = Int(color.greenComponent * 255)
            let blue = Int(color.blueComponent * 255)
            NotificationCenter.default.post(name: NSNotification.Name("ColorUpdated"), object: nil, userInfo: [
                "color": [red, green, blue],
                "x": mouseLocation.x,
                "y": mouseLocation.y
            ])
        }
    }

    private func getColorAtPosition(_ position: NSPoint, on screen: NSScreen) -> NSColor? {
        let image = CGWindowListCreateImage(
            CGRect(x: position.x, y: screen.frame.height - position.y, width: 1, height: 1),
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        if let image = image {
            let nsImage = NSImage(cgImage: image, size: NSSize(width: 1, height: 1))
            return nsImage.color(at: NSPoint(x: 0, y: 0))?.usingColorSpace(.sRGB)
        }
        return nil
    }

    @objc func stopColorPicking() {
        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil
        if let color = getColorAtMousePosition() {
            let red = Int(color.redComponent * 255)
            let green = Int(color.greenComponent * 255)
            let blue = Int(color.blueComponent * 255)
            flutterResult?([red, green, blue])
        } else {
            flutterResult?(FlutterError(code: "FAILED", message: "Failed to get color", details: nil))
        }
        flutterResult = nil
    }

    private func getColorAtMousePosition() -> NSColor? {
        let mouseLocation = NSEvent.mouseLocation
        if let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            let image = CGWindowListCreateImage(
                CGRect(x: mouseLocation.x, y: screenWithMouse.frame.height - mouseLocation.y, width: 1, height: 1),
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            )
            if let image = image {
                let nsImage = NSImage(cgImage: image, size: NSSize(width: 1, height: 1))
                if let color = nsImage.color(at: NSPoint(x: 0, y: 0)) {
                    return color.usingColorSpace(.sRGB) ?? color
                }
            }
        }
        return nil
    }
}

extension NSImage {
    func color(at point: NSPoint) -> NSColor? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let pixelData = cgImage.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(point.y)) + Int(point.x)) * 4
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
}