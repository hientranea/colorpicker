import Cocoa
import FlutterMacOS
import QuartzCore

@objc class ColorPicker: NSObject {
    private var isTracking = false
    private var flutterResult: FlutterResult?
    private var lastColor: NSColor?
    private var overlayWindow: NSWindow?
    private var circleLayer: CAShapeLayer?
    private var displayLink: CVDisplayLink?
    
    @objc func startColorPicking(result: @escaping FlutterResult) {
        guard !isTracking else { return }
        isTracking = true
        flutterResult = result
        createOverlayWindow()
        setupDisplayLink()
        result(nil)
    }
    
    @objc func getMagnifiedImage(x: CGFloat, y: CGFloat, result: @escaping FlutterResult) {
        guard let mainScreen = NSScreen.main else {
            result(FlutterError(code: "FAILED", message: "Main screen not found", details: nil))
            return
        }
        
        let size: CGFloat = 9 // Size of the magnified area
        let flippedY = mainScreen.frame.height - y
        guard let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: x, y: flippedY), $0.frame, false) }) else {
            result(FlutterError(code: "FAILED", message: "Screen not found", details: nil))
            return
        }
        
        let rectX = max(0, min(x - size/2, screenWithMouse.frame.width - size))
        let rectY = max(0, min(flippedY - size/2, screenWithMouse.frame.height - size))
        let rect = CGRect(x: rectX, y: rectY, width: size, height: size)
        
        guard let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            result(FlutterError(code: "FAILED", message: "Failed to capture screen", details: nil))
            return
        }
        
        let nsImage = NSImage(cgImage: image, size: NSSize(width: size, height: size))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            result(FlutterError(code: "FAILED", message: "Failed to create image data", details: nil))
            return
        }
        
        result(FlutterStandardTypedData(bytes: pngData))
    }
    
    @objc func saveCurrentColor() {
        guard let color = lastColor else { return }
        let rgb = color.rgbComponents
        NotificationCenter.default.post(name: NSNotification.Name("ColorSaved"), object: nil, userInfo: ["color": rgb])
    }
    
    @objc func stopColorPicking() {
        isTracking = false
        cleanupDisplayLink()
        destroyScreenOverlay()
    }
    
    @objc func getColorAtPosition(_ position: NSPoint) -> NSColor? {
        guard let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(position, $0.frame, false) }) else { return nil }
        return getColorAtPosition(position, on: screenWithMouse)
    }

    private func updateColorAtMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }),
              let color = getColorAtPosition(mouseLocation, on: screenWithMouse) else { return }
        
        lastColor = color
        let rgb = color.rgbComponents
        
        NotificationCenter.default.post(name: NSNotification.Name("ColorUpdated"), object: nil, userInfo: [
            "color": rgb,
            "x": mouseLocation.x,
            "y": mouseLocation.y
        ])
        
        updateCirclePosition(mouseLocation, color: color)
        
    }
    
    private func updateCirclePosition(_ position: NSPoint, color: NSColor) {
        guard let overlayWindow = overlayWindow else { return }
        let windowPosition = overlayWindow.convertPoint(fromScreen: position)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        circleLayer?.position = windowPosition
        let swappedColor = NSColor(red: color.blueComponent,
                                   green: color.greenComponent,
                                   blue: color.redComponent,
                                   alpha: color.alphaComponent)
        circleLayer?.strokeColor = swappedColor.cgColor
        CATransaction.commit()
    }
    
    private func getColorAtPosition(_ position: NSPoint, on screen: NSScreen) -> NSColor? {
        let rect = CGRect(x: position.x, y: screen.frame.height - position.y, width: 1, height: 1)
        guard let image = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else { return nil }
        let nsImage = NSImage(cgImage: image, size: NSSize(width: 1, height: 1))
        return nsImage.color(at: NSPoint(x: 0, y: 0))?.usingColorSpace(.sRGB)
    }
    
    private func getColorAtMousePosition() -> NSColor? {
        let mouseLocation = NSEvent.mouseLocation
        guard let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else { return nil }
        return getColorAtPosition(mouseLocation, on: screenWithMouse)
    }
    
    private func createOverlayWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        
        let window = NSWindow(contentRect: screen.frame,
                              styleMask: [.borderless, .fullSizeContentView],
                              backing: .buffered,
                              defer: false)
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.colorSpace = NSColorSpace.deviceRGB
        
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        circleLayer.path = CGPath(ellipseIn: circleLayer.bounds, transform: nil)
        circleLayer.fillColor = NSColor.clear.cgColor
        circleLayer.strokeColor = NSColor.red.cgColor
        circleLayer.lineWidth = 8
        
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.addSublayer(circleLayer)
        
        window.makeKeyAndOrderFront(nil)
        
        self.overlayWindow = window
        self.circleLayer = circleLayer
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { (_, _, _, _, _, displayLinkContext) -> CVReturn in
            let colorPicker = Unmanaged<ColorPicker>.fromOpaque(displayLinkContext!).takeUnretainedValue()
            DispatchQueue.main.async {
                colorPicker.updateColorAtMousePosition()
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink!)
    }
    
    private func destroyScreenOverlay() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupDisplayLink()
            self?.removeOverlayWindow()
        }
    }
    
    private func cleanupDisplayLink() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
    }
    
    private func removeOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        circleLayer = nil
    }
    
    private func printLog(log: String) {
        NotificationCenter.default.post(name: NSNotification.Name("log"), object: nil, userInfo: ["log": log])
    }
}

extension NSColor {
    var rgbComponents: [Int] {
        let color = self.usingColorSpace(.deviceRGB) ?? self
        return [Int(color.redComponent * 255),
                Int(color.greenComponent * 255),
                Int(color.blueComponent * 255)]
    }
}

extension NSImage {
    func color(at point: NSPoint) -> NSColor? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let pixelData = cgImage.dataProvider?.data else { return nil }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.size.width) * Int(point.y)) + Int(point.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / 255.0
        let g = CGFloat(data[pixelInfo+1]) / 255.0
        let b = CGFloat(data[pixelInfo+2]) / 255.0
        let a = CGFloat(data[pixelInfo+3]) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
}
