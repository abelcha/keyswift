import Cocoa
import Yams
// deflare a simple and quick log function:
let log = Logger.shared.log

public struct AppGroup {
    public let id: String
    public let bundleIDs: [String]
    public let fnKey: Int
    
    public init(id: String, bundleIDs: [String], fnKey: Int) {
        self.id = id
        self.bundleIDs = bundleIDs
        self.fnKey = fnKey
    }
}



public class WindowManager {
    // Config-driven app groups
    private let config: KeyShiftConfig
    private var appGroups: [AppGroup]
    private var groupsByFnKey: [Int: AppGroup]
    private var groupsById: [String: AppGroup]
    
    // Window focus tracking
    private var windowFocusTimes: [CGWindowID: Date] = [:]
    private var lastUsedWindows: [String: WindowInfo] = [:]
    
    public init(config: KeyShiftConfig) {
        self.config = config
        self.appGroups = config.appGroups
        self.groupsByFnKey = config.groupsByFnKey
        self.groupsById = config.groupsById
        
        logConfiguration()
    }

    // Log the loaded configuration
    private func logConfiguration() {
        Logger.shared.log("Loaded configuration with \(appGroups.count) groups:")
        for group in appGroups {
            Logger.shared.log("Group \(group.id) (F\(group.fnKey)): \(group.bundleIDs.joined(separator: ", "))")
        }
    }

    // Generic toggle function for any group
    func toggleWindowsForGroup(_ groupId: String) {
        guard let group = groupsById[groupId] else {
            Logger.shared.log("Unknown group: \(groupId)")
            return
        }
        Logger.shared.log("Attempting to toggle \(groupId) windows")
        switchBetweenApplicationWindows(bundleIDs: group.bundleIDs, windowType: groupId.capitalized)
    }

    // Generic cycle function for any group
    func cycleWindowsForGroup(_ groupId: String, forward: Bool = true) {
        guard let group = groupsById[groupId] else {
            Logger.shared.log("Unknown group: \(groupId)")
            return
        }
        Logger.shared.log("Attempting to cycle \(groupId) windows")
        cycleWindowsOfType(bundleIDs: group.bundleIDs, forward: forward, windowType: groupId.capitalized)
    }
    
    // MARK: - Public Methods
    
    public func getFnKeyMappings() -> [Int: String] {
        var mappings: [Int: String] = [:]
        for (fnKey, group) in groupsByFnKey {
            mappings[fnKey] = group.id
        }
        return mappings
    }
    
    // Function key based methods
    func toggleWindowsForFnKey(_ fnKey: Int) {
        guard let group = groupsByFnKey[fnKey] else {
            Logger.shared.log("No group configured for F\(fnKey)")
            return
        }
        toggleWindowsForGroup(group.id)
    }
    
    func cycleWindowsForFnKey(_ fnKey: Int, forward: Bool = true) {
        guard let group = groupsByFnKey[fnKey] else {
            Logger.shared.log("No group configured for F\(fnKey)")
            return
        }
        cycleWindowsForGroup(group.id, forward: forward)
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

        Logger.shared.log("Found \(appWindows.count) \(windowType) windows")
            
        if appWindows.isEmpty {
            launchDefaultAppForWindowType(windowType)
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
            // Sort windows by most recently used (excluding current window)
            let otherWindows = appWindows.filter { $0.windowID != frontmostWindow.windowID }
            let sortedWindows = otherWindows.sorted { window1, window2 in
                let time1 = windowFocusTimes[window1.windowID] ?? Date.distantPast
                let time2 = windowFocusTimes[window2.windowID] ?? Date.distantPast
                return time1 > time2  // Most recent first
            }
            
            if let secondWindow = sortedWindows.first {
                Logger.shared.log("Switching from current \(windowType) to most recently used \(windowType)")
                focusWindow(secondWindow)
                updateLastUsedWindow(secondWindow, windowType: windowType)
            }
        } else {
            // Currently in a window of a different type, try to restore the last used window
            // of the target type, or use the first available one if none was used before
            let groupId = windowType.lowercased()
            let windowToFocus: WindowInfo?

            if let lastWindow = lastUsedWindows[groupId],
               appWindows.contains(where: { $0.windowID == lastWindow.windowID })
            {
                windowToFocus = lastWindow
                Logger.shared.log("Focusing last used \(windowType) window: \(lastWindow.ownerName)")
            } else {
                windowToFocus = appWindows.first
                Logger.shared.log("No last used \(windowType) or not valid, focusing first \(windowType)")
            }

            if let window = windowToFocus {
                focusWindow(window)
                updateLastUsedWindow(window, windowType: windowType)
            }
        }
    }

    // Helper method to update the last used window for a given type
    private func updateLastUsedWindow(_ window: WindowInfo, windowType: String) {
        Logger.shared.log(
            "Updating last used \(windowType) window: \(window.ownerName), ID: \(window.windowID)")
        
        // Find the group ID from the window type
        let groupId = windowType.lowercased()
        lastUsedWindows[groupId] = window
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

        Logger.shared.log("Found \(appWindows.count) \(windowType) windows for cycling")

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
        Logger.shared.log("Cycling to next \(windowType), index \(nextIndex)")
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
        Logger.shared.log(
            "Focusing window ID: \(window.windowID), PID: \(window.ownerPID), App: \(window.ownerName)"
        )

        // First activate the application
        if let app = NSRunningApplication(processIdentifier: pid_t(window.ownerPID)) {
            let success = app.activate(options: .activateIgnoringOtherApps)
            if !success {
                Logger.shared.log("Failed to activate application")
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
            Logger.shared.log("Error getting windows: \(error)")
            return
        }

        guard let windowArray = windowList as? [AXUIElement] else {
            Logger.shared.log("Could not cast window list to array")
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
                
                // Record focus timestamp
                windowFocusTimes[window.windowID] = Date()
                
                Logger.shared.log("Window focused successfully")
                return
            }
        }

        Logger.shared.log("Could not find window with ID \(window.windowID) in application")
    }

    private func showAlert(message: String) {
        Logger.shared.log("ALERT: \(message)")
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    func switchToPreviousNonStandardWindow() {
        Logger.shared.log("Attempting to switch to previous non-standard window")

        // Get all running applications with their windows
        let runningApps = getRunningApps()
        
        // Collect all bundle IDs from all groups
        let allManagedBundleIDs = Set(appGroups.flatMap { $0.bundleIDs })

        // Filter for windows that are NOT in any managed group
        var appWindows: [WindowInfo] = []
        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
                !allManagedBundleIDs.contains(bundleID)
            {
                let windows = getVisibleWindowsForApp(app)
                appWindows.append(contentsOf: windows)
            }
        }

        Logger.shared.log("Found \(appWindows.count) non-standard windows")

        if appWindows.isEmpty {
            Logger.shared.log("No non-standard windows found")
            return
        }

        // Get currently focused window
        guard let frontmostWindow = getFrontmostWindow() else {
            if let window = appWindows.first {
                focusWindow(window)
            }
            return
        }

        // Find the window to focus (either the previous one or the first available)
        let windowToFocus =
            appWindows.first { $0.windowID != frontmostWindow.windowID } ?? appWindows.first

        if let window = windowToFocus {
            focusWindow(window)
        }
    }

    private func launchDefaultAppForWindowType(_ windowType: String) {
        let groupId = windowType.lowercased()
        guard let group = groupsById[groupId],
              let bundleID = group.bundleIDs.first else {
            showAlert(message: "No \(windowType) applications configured")
            return
        }

        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundleID,
            options: .default,
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil)
    }
}

// Window information structure
struct WindowInfo {
    let windowID: CGWindowID
    let ownerName: String
    let ownerPID: Int
    let frame: CGRect
}
