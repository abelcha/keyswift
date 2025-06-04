import Cocoa
import KeyShift

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowManager = WindowManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register hotkeys
        HotkeyManager.shared.registerHotkeys()
        
        // Hide from dock and menu bar
        NSApp.setActivationPolicy(.accessory)
    }
}

// Create and configure application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
app.run()
