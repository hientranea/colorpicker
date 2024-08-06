import Cocoa
import FlutterMacOS
import Foundation

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    private var colorPicker: ColorPicker?
    private var channel: FlutterMethodChannel?
    private var currentHotkey: [String] = ["Cmd", "L"]

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "com.example.colorpicker/color_picker", binaryMessenger: controller.engine.binaryMessenger)
        
        colorPicker = ColorPicker()
        
        channel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "startColorPicking":
                self.colorPicker?.startColorPicking(result: result)
            case "stopColorPicking":
                self.colorPicker?.stopColorPicking()
            case "getMagnifiedImage":
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? CGFloat,
                   let y = args["y"] as? CGFloat {
                    self.colorPicker?.getMagnifiedImage(x: x, y: y, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                }
            case "saveCurrentColor":
                self.colorPicker?.saveCurrentColor()
                result(nil)
            case "updateHotkey":
                self.updateHotkey(call, result: result)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let keyChar = event.charactersIgnoringModifiers ?? ""
            let pressedHotkey = self.getHotkeyArray(modifiers: modifiers, key: keyChar)

            if pressedHotkey == self.currentHotkey {
                self.colorPicker?.saveCurrentColor()
            }
            return event
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ColorUpdated"), object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let color = userInfo["color"] as? [Int],
               let x = userInfo["x"] as? CGFloat,
               let y = userInfo["y"] as? CGFloat {
                self?.channel?.invokeMethod("colorUpdated", arguments: [
                    "color": color,
                    "x": x,
                    "y": y
                ])
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ColorSaved"), object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let color = userInfo["color"] as? [Int] {
                self?.channel?.invokeMethod("colorSaved", arguments: [
                    "color": color
                ])
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("log"), object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo {
                self?.channel?.invokeMethod("log", arguments: [
                    "log": userInfo["log"]
                ])
            }
        }
        
        
        requestScreenCaptureAccess()
    }

    private func getHotkeyArray(modifiers: NSEvent.ModifierFlags, key: String) -> [String] {
        var hotkeyParts: [String] = []
        if modifiers.contains(.command) { hotkeyParts.append("Cmd") }
        if modifiers.contains(.option) { hotkeyParts.append("Option") }
        if modifiers.contains(.control) { hotkeyParts.append("Ctrl") }
        if modifiers.contains(.shift) { hotkeyParts.append("Shift") }
        hotkeyParts.append(key.uppercased())
        return hotkeyParts
    }

    @objc func updateHotkey(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let hotkey = call.arguments as? String {
            self.currentHotkey = hotkey.components(separatedBy: " + ")
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid hotkey", details: nil))
        }
    }
    
    private func requestScreenCaptureAccess() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Screen Recording Permission Required"
            alert.informativeText = "This app needs screen recording permission to pick colors. Please grant permission in System Preferences > Security & Privacy > Privacy > Screen Recording."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
        }
    }
}
