import Cocoa
import FlutterMacOS

@objc class ColorPicker: NSObject {
    @objc func pickColor(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if let color = self.getColorAtMousePosition() {
                let red = Int(color.redComponent * 255)
                let green = Int(color.greenComponent * 255)
                let blue = Int(color.blueComponent * 255)
                result([red, green, blue])
            } else {
                result(FlutterError(code: "FAILED", message: "Failed to get color", details: nil))
            }
        }
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
                    return color
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