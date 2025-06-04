import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager!
    private var hotkeyManager: HotkeyManager!
    private var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("KeyShift starting up...")
        
        // Request accessibility permissions if needed
        requestAccessibilityPermissions()
        
        // Initialize managers
        windowManager = WindowManager()
        print("WindowManager initialized")
        
        hotkeyManager = HotkeyManager(windowManager: windowManager)
        print("HotkeyManager initialized")
        
        // Setup menu bar icon
        setupStatusItem()
        print("Status item setup complete")
        
        // Register hotkeys
        registerHotkeys()
        print("Hotkeys registered - F1 for browsers, F2 for editors")
        print("KeyShift is now running!")
        
        // Show a visible notification that we're running
        let notification = NSUserNotification()
        notification.title = "KeyShift"
        notification.informativeText = "KeyShift is now running and listening for F1/F2 hotkeys"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            print("⚠️ Accessibility permissions not granted!")
            print("Please enable accessibility permissions for window switching to work.")
            print("Open System Preferences > Security & Privacy > Privacy > Accessibility")
            
            // Show a dialog to prompt the user
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "KeyShift needs accessibility permissions to function.\n\nPlease open System Preferences > Security & Privacy > Privacy > Accessibility and add this application."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let url = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
                NSWorkspace.shared.open(url)
            }
        } else {
            print("✅ Accessibility permissions granted")
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Use a standard image instead of SF Symbols for macOS 10.15 compatibility
        if let button = statusItem.button {
            button.image = NSImage(named: "NSWindow")
            if button.image == nil {
                // Fallback if NSWindow is not available
                let image = NSImage(size: NSSize(width: 18, height: 18))
                image.lockFocus()
                NSColor.black.setFill()
                NSBezierPath(rect: NSRect(x: 2, y: 2, width: 14, height: 14)).fill()
                image.unlockFocus()
                button.image = image
            }
            
            // Set a tooltip
            button.toolTip = "KeyShift - F1: Toggle browsers, F2: Toggle editors"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About KeyShift", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check Hotkey Status", action: #selector(checkHotkeys), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reinstall Hotkeys", action: #selector(reinstallHotkeys), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    private func registerHotkeys() {
        // We need to make sure the application is properly activated to receive hotkeys
        NSApp.activate(ignoringOtherApps: true)
        
        // Now register the hotkeys
        hotkeyManager.registerHotkeys()
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "KeyShift"
        alert.informativeText = "A native Swift app for switching between windows.\n\nHotkeys:\nF1: Toggle between browser windows\nF2: Toggle between editor windows\nCmd+F1: Cycle through browser windows\nCmd+F2: Cycle through editor windows"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func checkHotkeys() {
        let alert = NSAlert()
        alert.messageText = "Hotkey Status"
        
        // Get detailed status from the hotkey manager
        let statusDetails = hotkeyManager.getHotkeyStatus()
        
        alert.informativeText = "\(statusDetails)\n\nIf hotkeys aren't working, please ensure:\n\n1. KeyShift has accessibility permissions\n2. F1/F2 aren't being captured by system features or other apps\n3. Try reinstalling the hotkeys or restart the app"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func reinstallHotkeys() {
        // Unregister and re-register all hotkeys
        print("Reinstalling hotkeys...")
        hotkeyManager.registerHotkeys()
        
        // Show confirmation
        let alert = NSAlert()
        alert.messageText = "Hotkeys Reinstalled"
        alert.informativeText = "All hotkeys have been reinstalled. Try using F1 or F2 now."
        alert.alertStyle = .informational
        alert.runModal()
    }
}
