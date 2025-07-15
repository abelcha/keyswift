import Cocoa
import Foundation
import KeyShift
import SwiftUI

// Main entry point that handles version compatibility
func main() {
    if #available(macOS 13.0, *) {
        KeyShiftApp.main()
    } else {
        // Fallback to AppKit for older macOS versions
        let app = NSApplication.shared
        let delegate = LegacyAppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@available(macOS 13.0, *)
struct KeyShiftApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            LazyMenuBarView(appState: appState)
        } label: {
            Image(systemName: appState.currentIcon)
                .foregroundColor(.primary)
                .font(.system(size: 16, weight: .medium))
        }
        .menuBarExtraStyle(.menu)
    }
}

// Legacy AppKit delegate for older macOS versions
class LegacyAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        setupStatusBar()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "square.text.square", accessibilityDescription: "KeyShift")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        guard let appState = appState else { return }

        let menu = NSMenu()

        // Status item
        let statusMenuItem = NSMenuItem(
            title: "Last: \(appState.lastFocusedType.capitalized)", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(NSMenuItem.separator())

        // Groups
        for group in appState.config.appGroups {
            let groupItem = NSMenuItem(
                title: "\(group.id.capitalized) (F\(group.fnKey))", action: nil, keyEquivalent: "")
            let submenu = NSMenu()

            for bundleID in group.bundleIDs {
                let appItem = NSMenuItem(
                    title: bundleID, action: #selector(launchApp(_:)), keyEquivalent: "")
                appItem.target = self
                appItem.representedObject = bundleID
                submenu.addItem(appItem)
            }

            groupItem.submenu = submenu
            menu.addItem(groupItem)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit KeyShift", action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func launchApp(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }

        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundleID,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }
}

// Data structure to hold menu state snapshot
struct MenuData {
    let currentIcon: String
    let lastFocusedType: String
    let appGroups: [AppGroup]
}

main()

class AppState: ObservableObject {
    @Published var currentIcon = "square.text.square"
    @Published var lastFocusedType = "default"

    let config: KeyShiftConfig
    let windowManager: WindowManager
    let hotkeyManager: HotkeyManager

    init() {
        do {
            // Load configuration
            self.config = try KeyShiftConfig.loadConfig()

            // Initialize managers with config
            self.windowManager = WindowManager(config: config)
            self.hotkeyManager = HotkeyManager(windowManager: windowManager)

            setupApp()
        } catch {
            print("[KeyShift] ❌ Failed to load configuration: \(error)")
            print("[KeyShift] 💀 Application cannot continue without valid configuration")
            NSApplication.shared.terminate(nil)
            fatalError("Configuration loading failed: \(error)")
        }
    }

    private func setupApp() {
        // Register hotkeys
        hotkeyManager.registerHotkeys()

        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        Logger.shared.log("KeyShift started")

        // Log configuration
        for group in config.appGroups {
            Logger.shared.log(
                "Group \(group.id) (F\(group.fnKey)): \(group.bundleIDs.joined(separator: ", "))")
        }

        // Set up focus type monitoring
        setupFocusTypeMonitoring()
    }

    private func setupFocusTypeMonitoring() {
        // Monitor workspace notifications for app switching
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateIconForActiveApp(notification)
        }
    }

    private func updateIconForActiveApp(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication,
            let bundleID = app.bundleIdentifier
        else { return }
        // Determine which group this app belongs to
        for group in config.appGroups {
            if group.bundleIDs.contains(bundleID) {
                let newIcon = iconForGroupType(group.id, bundleID: bundleID)

                DispatchQueue.main.async {
                    if self.currentIcon != newIcon {
                        Logger.shared.log(
                            "🔄 Updating menu bar icon to \(newIcon) for group: \(group.id) (\(app.localizedName ?? bundleID))"
                        )
                        self.currentIcon = newIcon
                    }
                    // Only update lastFocusedType if it actually changed
                    if self.lastFocusedType != group.id {
                        self.lastFocusedType = group.id
                    }
                }
                return
            }
        }

        // Default icon if app doesn't belong to any configured group
        DispatchQueue.main.async {
            if self.currentIcon != "square.text.square" {
                Logger.shared.log(
                    "🔄 Switching menu bar icon to default for app: \(app.localizedName ?? bundleID)"
                )
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.currentIcon = "square.text.square"
                }
            }
            // Only update lastFocusedType if it actually changed
            if self.lastFocusedType != "default" {
                self.lastFocusedType = "default"
            }
        }
    }
    private func extractAppNameFromBundleID(_ bundleID: String) -> String {
        // Extract the last component after the last dot
        let components = bundleID.components(separatedBy: ".")
        return components.last ?? bundleID
    }

    private func isValidSFSymbol(_ symbolName: String) -> Bool {
        // Check if the symbol name exists as an SF Symbol
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil
    }

    func iconForGroupType(_ groupType: String, bundleID: String? = nil) -> String {
        Logger.shared.log("Determining icon for group type: \(groupType) (\(bundleID ?? "nil"))")
        // First try to use app name as SF Symbol if it exists
        if let bundleID = bundleID {
            // Extract app name from bundle ID and try as SF Symbol
            let appName = extractAppNameFromBundleID(bundleID).lowercased()
            Logger.shared.log("App name: \(appName)")
            
            
            let lowercaseBundleID = bundleID.lowercased()
            // Sublime Text variants
            if lowercaseBundleID.contains("trae") {
                return "inset.filled.bottomthird.square"
            }
            // Bundle ID pattern matching - each app gets a unique, consistent icon
            // Chrome-based browsers
            if lowercaseBundleID.contains("chromium") {
                return "circle.dotted.circle"
            }
            if lowercaseBundleID.contains("chrome") {
                return "globe.americas"
            }
            // Safari-based browsers
            if lowercaseBundleID.contains("safari") {
                return "safari"
            }
            if lowercaseBundleID.contains("orion") {
                return "safari.fill"
            }
            // Firefox-based browsers
            if lowercaseBundleID.contains("firefox") {
                return "flame"
            }
            // Xcode variants
            if lowercaseBundleID.contains("xcode") {
                return "hammer.circle"
            }
            // VS Code variants

            // Terminal variants
            if lowercaseBundleID.contains("term") {
                return "apple.terminal"
            }
            if lowercaseBundleID.contains("code") {
                return "chevron.left.forwardslash.chevron.right"
            }
            if isValidSFSymbol(appName) {
                return appName
            }
        }

        // Group-based fallback icons - different from specific app icons
        switch groupType.lowercased() {
        case "browsers":
            return "globe"  // Different from safari, globe.americas, flame
        case "editors":
            return "curlybraces"  // Different from chevron.left.forwardslash.chevron.right, hammer, doc.text
        case "terminals":
            return "terminal.fill"  // Different from terminal, square.split.2x1
        default:
            return "square.text.square"
        }
    }
}

// Lazy-loaded menu view that only renders when menu is opened
struct LazyMenuBarView: View {
    let appState: AppState
    @State private var menuData: MenuData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let data = menuData {
                // Status section
                HStack {
                    Image(systemName: data.currentIcon)
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("KeyShift")
                        .font(.system(size: 14, weight: .medium))
                    Text("Active: \(data.lastFocusedType.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                // Groups section
                ForEach(data.appGroups, id: \.id) { group in
                    Menu {
                        ForEach(group.bundleIDs, id: \.self) { bundleID in
                            Button(bundleID) {
                                launchApp(bundleID: bundleID)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: appState.iconForGroupType(group.id))
                            Text("\(group.id.capitalized) (F\(group.fnKey))")
                            Spacer()
                            Text("\(group.bundleIDs.count) apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Actions
                Button("Quit KeyShift") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            } else {
                Text("Loading...")
                    .onAppear {
                        loadMenuData()
                    }
            }
        }
        .frame(minWidth: 200)
    }
    
    private func loadMenuData() {
        // Only load menu data when menu is actually opened
        menuData = MenuData(
            currentIcon: appState.currentIcon,
            lastFocusedType: appState.lastFocusedType,
            appGroups: appState.config.appGroups
        )
    }

    private func launchApp(bundleID: String) {
        if #available(macOS 11.0, *) {
            // Use modern API
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            else {
                Logger.shared.log("Could not find application with bundle ID: \(bundleID)")
                return
            }

            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) {
                app, error in
                if let error = error {
                    Logger.shared.log("Failed to launch \(bundleID): \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback for older macOS versions
            NSWorkspace.shared.launchApplication(
                withBundleIdentifier: bundleID,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        }
    }
}
