import Cocoa
import KeyShift
import Foundation

// Parse command line arguments
let isDaemon = CommandLine.arguments.contains("--daemon")

// Daemonize if requested
if isDaemon {
    // Get current executable path
    let execPath = URL(fileURLWithPath: CommandLine.arguments[0])
    
    // Launch new instance without terminal
    let config = NSWorkspace.OpenConfiguration()
    config.activates = false
    
    NSWorkspace.shared.openApplication(at: execPath, configuration: config) { app, error in
    if error != nil {
        Logger.shared.log("Failed to daemonize")
        exit(1)
    }
        exit(0)
    }
    
    // Wait for launch to complete
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    exit(0)
}

// Check if another instance is running
let pingName = NSNotification.Name("com.example.KeyShift.ping")
let pongName = NSNotification.Name("com.example.KeyShift.pong")
let center = DistributedNotificationCenter.default()

var isRunning = false
let observer = center.addObserver(forName: pongName, object: nil, queue: nil) { _ in
    isRunning = true
}

// Post a notification and wait for response
center.postNotificationName(pingName, object: nil)
RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
center.removeObserver(observer)

if isRunning {
    Logger.shared.log("KeyShift is already running")
    exit(0)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let windowManager = WindowManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register hotkeys
        HotkeyManager.shared.registerHotkeys()
        
        // Hide from dock and menu bar
        NSApp.setActivationPolicy(isDaemon ? .prohibited : .accessory)
        
        // Listen for other instances
        DistributedNotificationCenter.default().addObserver(
            forName: pingName,
            object: nil,
            queue: nil
        ) { _ in
            // Respond to ping to indicate we're running
            DistributedNotificationCenter.default().postNotificationName(pongName, object: nil)
        }
        
        Logger.shared.log("KeyShift started" + (isDaemon ? " in daemon mode" : ""))
        
        // Log hotkey registration status
        Logger.shared.log(HotkeyManager.shared.getHotkeyStatus())
    }
}

// Create and configure application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
app.run()
