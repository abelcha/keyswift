import Cocoa
import Carbon

public class HotkeyManager {
    private let windowManager: WindowManager
    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotkeys: [Int: EventHotKeyRef?] = [:]
    
    // Define hotkey IDs
    private enum HotkeyID: Int {
        case toggleBrowsers = 1
        case toggleEditors = 2
        case toggleTerminals = 3
        case cycleBrowsersForward = 4
        case cycleEditorsForward = 5
        case cycleTerminalsForward = 6
    }
    
    public static let shared = HotkeyManager(windowManager: WindowManager())
    
    public init(windowManager: WindowManager) {
        self.windowManager = windowManager
        print("HotkeyManager: Initialized")
    }
    
    public func registerHotkeys() {
        print("HotkeyManager: Registering hotkeys...")
        
        // Register for hotkey events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Install event handler
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                guard let event = event else { 
                    print("HotkeyManager: Received nil event")
                    return noErr 
                }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                print("HotkeyManager: Received hotkey event")
                manager.handleHotkeyEvent(event)
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        
        if result != noErr {
            print("HotkeyManager: Failed to install event handler, error: \(result)")
        } else {
            print("HotkeyManager: Successfully installed event handler")
        }
        
        // Register individual hotkeys
        registerHotkey(
            id: HotkeyID.toggleBrowsers.rawValue,
            key: UInt32(kVK_F1),
            modifiers: 0,
            name: "F1 (Toggle Browsers)"
        )
        
        registerHotkey(
            id: HotkeyID.toggleEditors.rawValue,
            key: UInt32(kVK_F2), 
            modifiers: 0,
            name: "F2 (Toggle Editors)"
        )
        
        registerHotkey(
            id: HotkeyID.cycleBrowsersForward.rawValue,
            key: UInt32(kVK_F1),
            modifiers: UInt32(cmdKey),
            name: "Cmd+F1 (Cycle Browsers)"
        )
        
        registerHotkey(
            id: HotkeyID.cycleEditorsForward.rawValue,
            key: UInt32(kVK_F2),
            modifiers: UInt32(cmdKey),
            name: "Cmd+F2 (Cycle Editors)"
        )
        
        // Register F3 hotkeys for terminal windows
        registerHotkey(
            id: HotkeyID.toggleTerminals.rawValue,
            key: UInt32(kVK_F3),
            modifiers: 0,
            name: "F3 (Toggle Terminals)"
        )
        
        registerHotkey(
            id: HotkeyID.cycleTerminalsForward.rawValue,
            key: UInt32(kVK_F3),
            modifiers: UInt32(cmdKey),
            name: "Cmd+F3 (Cycle Terminals)"
        )
        
        // Log registered hotkeys summary
        print("HotkeyManager: Registered \(registeredHotkeys.count) hotkeys successfully")
    }
    
    private func registerHotkey(id: Int, key: UInt32, modifiers: UInt32, name: String) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x5753), id: UInt32(id)) // 'WS' for KeyShift
        
        let status = RegisterEventHotKey(
            key,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("HotkeyManager: Failed to register hotkey \(name), error: \(status)")
        } else {
            print("HotkeyManager: Successfully registered hotkey \(name)")
            registeredHotkeys[id] = hotKeyRef
        }
    }
    
    private func handleHotkeyEvent(_ event: EventRef) {
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        if status != noErr {
            print("HotkeyManager: Failed to get hotkey ID from event, error: \(status)")
            return
        }
        
        guard let keyID = HotkeyID(rawValue: Int(hotkeyID.id)) else { 
            print("HotkeyManager: Unknown hotkey ID: \(hotkeyID.id)")
            return 
        }
        
        print("HotkeyManager: Received hotkey event for ID: \(keyID)")
        
        DispatchQueue.main.async {
            switch keyID {
            case .toggleBrowsers:
                print("HotkeyManager: Toggling browsers")
                self.windowManager.toggleBrowserWindows()
            case .toggleEditors:
                print("HotkeyManager: Toggling editors")
                self.windowManager.toggleEditorWindows()
            case .toggleTerminals:
                print("HotkeyManager: Toggling terminals")
                self.windowManager.toggleTerminalWindows()
            case .cycleBrowsersForward:
                print("HotkeyManager: Cycling browsers forward")
                self.windowManager.cycleBrowserWindows(forward: true)
            case .cycleEditorsForward:
                print("HotkeyManager: Cycling editors forward")
                self.windowManager.cycleEditorWindows(forward: true)
            case .cycleTerminalsForward:
                print("HotkeyManager: Cycling terminals forward")
                self.windowManager.cycleTerminalWindows(forward: true)
            }
        }
    }
    
    // Check if a hotkey is currently registered
    func isHotkeyRegistered(id: Int) -> Bool {
        return registeredHotkeys[id] != nil
    }
    
    // Get a diagnostic summary of hotkey registration
    func getHotkeyStatus() -> String {
        var status = "Hotkey Status:\n"
        
        let f1Status = isHotkeyRegistered(id: HotkeyID.toggleBrowsers.rawValue)
        let f2Status = isHotkeyRegistered(id: HotkeyID.toggleEditors.rawValue)
        let f3Status = isHotkeyRegistered(id: HotkeyID.toggleTerminals.rawValue)
        let cmdF1Status = isHotkeyRegistered(id: HotkeyID.cycleBrowsersForward.rawValue)
        let cmdF2Status = isHotkeyRegistered(id: HotkeyID.cycleEditorsForward.rawValue)
        let cmdF3Status = isHotkeyRegistered(id: HotkeyID.cycleTerminalsForward.rawValue)
        
        status += "F1 (Toggle Browsers): \(f1Status ? "Registered" : "Failed")\n"
        status += "F2 (Toggle Editors): \(f2Status ? "Registered" : "Failed")\n"
        status += "F3 (Toggle Terminals): \(f3Status ? "Registered" : "Failed")\n"
        status += "Cmd+F1 (Cycle Browsers): \(cmdF1Status ? "Registered" : "Failed")\n"
        status += "Cmd+F2 (Cycle Editors): \(cmdF2Status ? "Registered" : "Failed")\n"
        status += "Cmd+F3 (Cycle Terminals): \(cmdF3Status ? "Registered" : "Failed")\n"
        
        return status
    }
}
