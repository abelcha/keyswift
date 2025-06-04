import Cocoa

public class WindowManager {
    public init() {}
    // Browser bundle IDs - from your Hammerspoon script
    private let browserBundleIDs = [
        "com.apple.Safari", "com.brave.Browser", "com.kagi.kagimacOS",
        "org.chromium.Chromium", "com.google.Chrome.canary", "com.google.Chrome.dev",
        "com.google.Chrome", "company.thebrowser.Browser", "org.mozilla.firefox",
        "org.chromium.Thorium", "com.sigmaos.sigmaos.macos", "com.microsoft.edgemac",
        "com.apple.SafariTechnologyPreview", "com.duckduckgo.macos.browser",
        "org.torproject.torbrowser",
    ]

    // Code editor bundle IDs - from your Hammerspoon script
    private let editorBundleIDs = [
        "com.microsoft.VSCodeInsiders", "com.exafunction.windsurf", "com.vscodium.VSCodiumInsiders",
        "com.vscodium",
        "io.lapce", "com.microsoft.VSCode",
        "dev.zed.Zed", "com.todesktop.230313mzl4w4u92",
    ]

    // Terminal bundle IDs
    private let terminalBundleIDs = [
        "com.googlecode.iterm2", "com.apple.Terminal", "co.zeit.hyper",
        "com.github.wez.wezterm", "dev.alacritty", "io.alacritty", "com.kovidgoyal.kitty",
    ]

    // Track last used window for each category
    private var lastUsedBrowserWindow: WindowInfo?
    private var lastUsedEditorWindow: WindowInfo?
    private var lastUsedTerminalWindow: WindowInfo?

    // Toggle between browser windows (F1 functionality)
    func toggleBrowserWindows() {
        print("Attempting to toggle browser windows")
        switchBetweenApplicationWindows(bundleIDs: browserBundleIDs, windowType: "Browser")
    }

    // Toggle between editor windows (F2 functionality)
    func toggleEditorWindows() {
        print("Attempting to toggle editor windows")
        switchBetweenApplicationWindows(bundleIDs: editorBundleIDs, windowType: "Code Editor")
    }

    // Cycle through browser windows (Cmd+F1 functionality)
    func cycleBrowserWindows(forward: Bool = true) {
        print("Attempting to cycle browser windows")
        cycleWindowsOfType(bundleIDs: browserBundleIDs, forward: forward, windowType: "Browser")
    }

    // Cycle through editor windows (Cmd+F2 functionality)
    func cycleEditorWindows(forward: Bool = true) {
        print("Attempting to cycle editor windows")
        cycleWindowsOfType(bundleIDs: editorBundleIDs, forward: forward, windowType: "Code Editor")
    }

    // Toggle between terminal windows (F3 functionality)
    func toggleTerminalWindows() {
        print("Attempting to toggle terminal windows")
        switchBetweenApplicationWindows(bundleIDs: terminalBundleIDs, windowType: "Terminal")
    }

    // Cycle through terminal windows (Cmd+F3 functionality)
    func cycleTerminalWindows(forward: Bool = true) {
        print("Attempting to cycle terminal windows")
        cycleWindowsOfType(bundleIDs: terminalBundleIDs, forward: forward, windowType: "Terminal")
    }

    // MARK: - Private Methods

    private func switchBetweenApplicationWindows(bundleIDs: [String], windowType: String) {
        // Get all running applications with their windows
        let runningApps = getRunningApps()

        // Filter for our target application types and their visible windows
        var appWindows: [WindowInfo] = []
        for app in runningApps {
            if let bundleID = app.bundleIdentifier, bundleIDs.contains(bundleID) {
                let windows = getVisibleWindowsForApp(app)
                appWindows.append(contentsOf: windows)
            }
        }

        print("Found \(appWindows.count) \(windowType) windows")

        if appWindows.isEmpty {
            launchDefaultAppForWindowType(windowType)
            return
        }

        if appWindows.count == 1, let window = appWindows.first {
            focusWindow(window)
            updateLastUsedWindow(window, windowType: windowType)
            return
        }

        // Get currently focused window
        guard let frontmostWindow = getFrontmostWindow() else {
            if let window = appWindows.first {
                focusWindow(window)
                updateLastUsedWindow(window, windowType: windowType)
            }
            return
        }

        // Get the app of the frontmost window
        let frontApp = NSWorkspace.shared.frontmostApplication
        let frontBundleID = frontApp?.bundleIdentifier

        // Check if current window is of the target type
        let isCurrentWindowOfTargetType = frontBundleID != nil && bundleIDs.contains(frontBundleID!)

        if isCurrentWindowOfTargetType {
            // Currently in a window of the target type, so switch to another window of this type
            if let secondWindow = appWindows.first(where: {
                $0.windowID != frontmostWindow.windowID
            }) {
                print("Switching from current \(windowType) to another \(windowType)")
                focusWindow(secondWindow)
                updateLastUsedWindow(secondWindow, windowType: windowType)
            }
        } else {
            // Currently in a window of a different type, try to restore the last used window
            // of the target type, or use the first available one if none was used before
            let windowToFocus: WindowInfo?

            if windowType == "Browser" {
                // Check if we have a recorded last used browser window and if it's still valid
                if let lastBrowser = lastUsedBrowserWindow,
                    appWindows.contains(where: { $0.windowID == lastBrowser.windowID })
                {
                    windowToFocus = lastBrowser
                    print("Focusing last used browser window: \(lastBrowser.ownerName)")
                } else {
                    windowToFocus = appWindows.first
                    print("No last used browser or not valid, focusing first browser")
                }
            } else if windowType == "Code Editor" {
                if let lastEditor = lastUsedEditorWindow,
                    appWindows.contains(where: { $0.windowID == lastEditor.windowID })
                {
                    windowToFocus = lastEditor
                    print("Focusing last used editor window: \(lastEditor.ownerName)")
                } else {
                    windowToFocus = appWindows.first
                    print("No last used editor or not valid, focusing first editor")
                }
            } else if windowType == "Terminal" {
                if let lastTerminal = lastUsedTerminalWindow,
                    appWindows.contains(where: { $0.windowID == lastTerminal.windowID })
                {
                    windowToFocus = lastTerminal
                    print("Focusing last used terminal window: \(lastTerminal.ownerName)")
                } else {
                    windowToFocus = appWindows.first
                    print("No last used terminal or not valid, focusing first terminal")
                }
            } else {
                windowToFocus = appWindows.first
            }

            if let window = windowToFocus {
                focusWindow(window)
                updateLastUsedWindow(window, windowType: windowType)
            }
        }
    }

    // Helper method to update the last used window for a given type
    private func updateLastUsedWindow(_ window: WindowInfo, windowType: String) {
        print(
            "Updating last used \(windowType) window: \(window.ownerName), ID: \(window.windowID)")

        switch windowType {
        case "Browser":
            lastUsedBrowserWindow = window
        case "Code Editor":
            lastUsedEditorWindow = window
        case "Terminal":
            lastUsedTerminalWindow = window
        default:
            break
        }
    }

    private func cycleWindowsOfType(bundleIDs: [String], forward: Bool, windowType: String) {
        // Get all running applications with their windows
        let runningApps = getRunningApps()

        // Filter for our target application types and their visible windows
        var appWindows: [WindowInfo] = []
        for app in runningApps {
            if let bundleID = app.bundleIdentifier, bundleIDs.contains(bundleID) {
                let windows = getVisibleWindowsForApp(app)
                appWindows.append(contentsOf: windows)
            }
        }

        print("Found \(appWindows.count) \(windowType) windows for cycling")

        if appWindows.isEmpty {
            launchDefaultAppForWindowType(windowType)
            return
        }

        if appWindows.count == 1, let window = appWindows.first {
            focusWindow(window)
            updateLastUsedWindow(window, windowType: windowType)
            return
        }

        // Sort windows by window ID for stable cycling
        let sortedWindows = appWindows.sorted { $0.windowID < $1.windowID }

        // Find current window index
        guard let frontmostWindow = getFrontmostWindow(),
            let currentIndex = sortedWindows.firstIndex(where: {
                $0.windowID == frontmostWindow.windowID && $0.ownerPID == frontmostWindow.ownerPID
            })
        else {
            // No current window of this type found, focus first one
            if let window = sortedWindows.first {
                focusWindow(window)
                updateLastUsedWindow(window, windowType: windowType)
            }
            return
        }

        // Determine next window index
        var nextIndex: Int
        if forward {
            nextIndex = (currentIndex + 1) % sortedWindows.count
        } else {
            nextIndex = (currentIndex - 1 + sortedWindows.count) % sortedWindows.count
        }

        // Focus next window
        print("Cycling to next \(windowType), index \(nextIndex)")
        let nextWindow = sortedWindows[nextIndex]
        focusWindow(nextWindow)
        updateLastUsedWindow(nextWindow, windowType: windowType)
    }

    // MARK: - Window Management Utilities

    private func getRunningApps() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications.filter { app in
            return app.activationPolicy == .regular  // Only regular applications, not UI elements or background apps
        }
    }

    private func getVisibleWindowsForApp(_ app: NSRunningApplication) -> [WindowInfo] {
        var windows: [WindowInfo] = []

        // Get all windows on screen
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return []
        }

        // Filter for windows belonging to this app
        for windowDict in windowList {
            guard let windowIDInt = windowDict[kCGWindowNumber as String] as? Int,
                let ownerPID = windowDict[kCGWindowOwnerPID as String] as? Int,
                ownerPID == app.processIdentifier,
                let bounds = windowDict[kCGWindowBounds as String] as? [String: Any],
                let isOnscreen = windowDict[kCGWindowIsOnscreen as String] as? Bool,
                isOnscreen,
                let layer = windowDict[kCGWindowLayer as String] as? Int,
                layer == 0  // Only consider normal windows, not floating or other special types
            else {
                continue
            }

            // Convert Int to CGWindowID (UInt32)
            let windowID = CGWindowID(UInt32(windowIDInt))

            // Parse window bounds
            let x = bounds["X"] as? CGFloat ?? 0
            let y = bounds["Y"] as? CGFloat ?? 0
            let width = bounds["Width"] as? CGFloat ?? 0
            let height = bounds["Height"] as? CGFloat ?? 0

            // Skip tiny windows that might be minimized or hidden
            if width < 50 || height < 50 {
                continue
            }

            let windowFrame = CGRect(x: x, y: y, width: width, height: height)
            let windowInfo = WindowInfo(
                windowID: windowID,
                ownerName: app.bundleIdentifier ?? "unknown",
                ownerPID: ownerPID,
                frame: windowFrame
            )
            windows.append(windowInfo)
        }

        return windows
    }

    private func getFrontmostWindow() -> WindowInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return nil
        }

        // The frontmost window should be the first one in the list that belongs to the frontmost app
        for windowDict in windowList {
            guard let windowIDInt = windowDict[kCGWindowNumber as String] as? Int,
                let ownerPID = windowDict[kCGWindowOwnerPID as String] as? Int,
                ownerPID == frontApp.processIdentifier,
                let bounds = windowDict[kCGWindowBounds as String] as? [String: Any],
                let layer = windowDict[kCGWindowLayer as String] as? Int,
                layer == 0  // Only consider normal windows, not floating
            else {
                continue
            }

            // Convert Int to CGWindowID (UInt32)
            let windowID = CGWindowID(UInt32(windowIDInt))

            // First window in the list is frontmost
            let x = bounds["X"] as? CGFloat ?? 0
            let y = bounds["Y"] as? CGFloat ?? 0
            let width = bounds["Width"] as? CGFloat ?? 0
            let height = bounds["Height"] as? CGFloat ?? 0

            // Skip tiny windows
            if width < 50 || height < 50 {
                continue
            }

            let windowFrame = CGRect(x: x, y: y, width: width, height: height)
            return WindowInfo(
                windowID: windowID,
                ownerName: frontApp.bundleIdentifier ?? "unknown",
                ownerPID: ownerPID,
                frame: windowFrame
            )
        }

        return nil
    }

    private func focusWindow(_ window: WindowInfo) {
        print(
            "Focusing window ID: \(window.windowID), PID: \(window.ownerPID), App: \(window.ownerName)"
        )

        // First activate the application
        if let app = NSRunningApplication(processIdentifier: pid_t(window.ownerPID)) {
            let success = app.activate(options: .activateIgnoringOtherApps)
            if !success {
                print("Failed to activate application")
                return
            }
        }

        // Then focus the specific window using Accessibility API
        let appElement = AXUIElementCreateApplication(pid_t(window.ownerPID))

        // Find the window with the matching ID
        var windowList: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            appElement, kAXWindowsAttribute as CFString, &windowList)

        if error != AXError.success {
            print("Error getting windows: \(error)")
            return
        }

        guard let windowArray = windowList as? [AXUIElement] else {
            print("Could not cast window list to array")
            return
        }

        for windowElement in windowArray {
            var windowID: CGWindowID = 0
            let error = _AXUIElementGetWindow(windowElement, &windowID)

            if error == AXError.success, windowID == window.windowID {
                // Found our window, make it frontmost
                AXUIElementSetAttributeValue(
                    windowElement, kAXMainAttribute as CFString, kCFBooleanTrue)
                AXUIElementSetAttributeValue(
                    windowElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
                print("Window focused successfully")
                return
            }
        }

        print("Could not find window with ID \(window.windowID) in application")
    }

    private func showAlert(message: String) {
        print("ALERT: \(message)")
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func launchDefaultAppForWindowType(_ windowType: String) {
        let bundleID: String?
        
        switch windowType {
        case "Browser":
            bundleID = "com.apple.Safari"
        case "Code Editor":
            bundleID = "com.microsoft.VSCodeInsiders"
        case "Terminal":
            bundleID = "com.googlecode.iterm2"
        default:
            bundleID = nil
        }

        if let bundleID = bundleID {
            NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleID,
                                               options: .default,
                                               additionalEventParamDescriptor: nil,
                                               launchIdentifier: nil)
        } else {
            showAlert(message: "No \(windowType) windows found")
        }
    }
}

// Window information structure
struct WindowInfo {
    let windowID: CGWindowID
    let ownerName: String
    let ownerPID: Int
    let frame: CGRect
}
