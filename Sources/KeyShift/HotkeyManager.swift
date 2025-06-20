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
        case ctrlF1Forward = 7
        case ctrlF2Forward = 8
        case ctrlF3Forward = 9
        case ctrlF4Forward = 10
        case ctrlF5Forward = 11
        case ctrlF6Forward = 12
        case ctrlF7Forward = 13
        case ctrlF8Forward = 14
        case ctrlF9Forward = 15
        case ctrlF10Forward = 16
        case ctrlF11Forward = 17
        case ctrlF12Forward = 18
        case cmdEscapePreviousWindow = 19
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
        
        // Register Control+Function key forwarding hotkeys
        registerHotkey(
            id: HotkeyID.ctrlF1Forward.rawValue,
            key: UInt32(kVK_F1),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F1 (Forward F1)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF2Forward.rawValue,
            key: UInt32(kVK_F2),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F2 (Forward F2)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF3Forward.rawValue,
            key: UInt32(kVK_F3),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F3 (Forward F3)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF4Forward.rawValue,
            key: UInt32(kVK_F4),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F4 (Forward F4)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF5Forward.rawValue,
            key: UInt32(kVK_F5),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F5 (Forward F5)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF6Forward.rawValue,
            key: UInt32(kVK_F6),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F6 (Forward F6)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF7Forward.rawValue,
            key: UInt32(kVK_F7),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F7 (Forward F7)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF8Forward.rawValue,
            key: UInt32(kVK_F8),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F8 (Forward F8)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF9Forward.rawValue,
            key: UInt32(kVK_F9),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F9 (Forward F9)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF10Forward.rawValue,
            key: UInt32(kVK_F10),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F10 (Forward F10)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF11Forward.rawValue,
            key: UInt32(kVK_F11),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F11 (Forward F11)"
        )
        
        registerHotkey(
            id: HotkeyID.ctrlF12Forward.rawValue,
            key: UInt32(kVK_F12),
            modifiers: UInt32(controlKey),
            name: "Ctrl+F12 (Forward F12)"
        )
        
        registerHotkey(
            id: HotkeyID.cmdEscapePreviousWindow.rawValue,
            key: UInt32(kVK_Escape),
            modifiers: UInt32(cmdKey),
            name: "Cmd+Escape (Previous Window)"
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
            case .ctrlF1Forward:
                print("HotkeyManager: Forwarding Ctrl+F1 to F1")
                self.sendFunctionKey(kVK_F1)
            case .ctrlF2Forward:
                print("HotkeyManager: Forwarding Ctrl+F2 to F2")
                self.sendFunctionKey(kVK_F2)
            case .ctrlF3Forward:
                print("HotkeyManager: Forwarding Ctrl+F3 to F3")
                self.sendFunctionKey(kVK_F3)
            case .ctrlF4Forward:
                print("HotkeyManager: Forwarding Ctrl+F4 to F4")
                self.sendFunctionKey(kVK_F4)
            case .ctrlF5Forward:
                print("HotkeyManager: Forwarding Ctrl+F5 to F5")
                self.sendFunctionKey(kVK_F5)
            case .ctrlF6Forward:
                print("HotkeyManager: Forwarding Ctrl+F6 to F6")
                self.sendFunctionKey(kVK_F6)
            case .ctrlF7Forward:
                print("HotkeyManager: Forwarding Ctrl+F7 to F7")
                self.sendFunctionKey(kVK_F7)
            case .ctrlF8Forward:
                print("HotkeyManager: Forwarding Ctrl+F8 to F8")
                self.sendFunctionKey(kVK_F8)
            case .ctrlF9Forward:
                print("HotkeyManager: Forwarding Ctrl+F9 to F9")
                self.sendFunctionKey(kVK_F9)
            case .ctrlF10Forward:
                print("HotkeyManager: Forwarding Ctrl+F10 to F10")
                self.sendFunctionKey(kVK_F10)
            case .ctrlF11Forward:
                print("HotkeyManager: Forwarding Ctrl+F11 to F11")
                self.sendFunctionKey(kVK_F11)
            case .ctrlF12Forward:
                print("HotkeyManager: Forwarding Ctrl+F12 to F12")
                self.sendFunctionKey(kVK_F12)
            case .cmdEscapePreviousWindow:
                print("HotkeyManager: Switching to previous non-editor/terminal/browser window")
                self.windowManager.switchToPreviousNonStandardWindow()
            }
        }
    }
    
    // Send a function key event programmatically
    private func sendFunctionKey(_ keyCode: Int) {
        let source = CGEventSource(stateID: .privateState)
        
        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true) else {
            print("HotkeyManager: Failed to create key down event for key \(keyCode)")
            return
        }
        
        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
            print("HotkeyManager: Failed to create key up event for key \(keyCode)")
            return
        }
        
        // Set the event to be sent to the active application
        keyDownEvent.setIntegerValueField(.eventSourceUserData, value: 1)
        keyUpEvent.setIntegerValueField(.eventSourceUserData, value: 1)
        
        // Post the events to the active application
        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
        keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
        
        print("HotkeyManager: Successfully sent function key \(keyCode) to active application")
    }
    
    // Check if a hotkey is currently registered
    func isHotkeyRegistered(id: Int) -> Bool {
        return registeredHotkeys[id] != nil
    }
    
    // Get a diagnostic summary of hotkey registration
    public func getHotkeyStatus() -> String {
        var status = "Hotkey Status:\n"
        
        let f1Status = isHotkeyRegistered(id: HotkeyID.toggleBrowsers.rawValue)
        let f2Status = isHotkeyRegistered(id: HotkeyID.toggleEditors.rawValue)
        let f3Status = isHotkeyRegistered(id: HotkeyID.toggleTerminals.rawValue)
        let cmdF1Status = isHotkeyRegistered(id: HotkeyID.cycleBrowsersForward.rawValue)
        let cmdF2Status = isHotkeyRegistered(id: HotkeyID.cycleEditorsForward.rawValue)
        let cmdF3Status = isHotkeyRegistered(id: HotkeyID.cycleTerminalsForward.rawValue)
        let ctrlF1Status = isHotkeyRegistered(id: HotkeyID.ctrlF1Forward.rawValue)
        let ctrlF2Status = isHotkeyRegistered(id: HotkeyID.ctrlF2Forward.rawValue)
        let ctrlF3Status = isHotkeyRegistered(id: HotkeyID.ctrlF3Forward.rawValue)
        let ctrlF4Status = isHotkeyRegistered(id: HotkeyID.ctrlF4Forward.rawValue)
        let ctrlF5Status = isHotkeyRegistered(id: HotkeyID.ctrlF5Forward.rawValue)
        let ctrlF6Status = isHotkeyRegistered(id: HotkeyID.ctrlF6Forward.rawValue)
        let ctrlF7Status = isHotkeyRegistered(id: HotkeyID.ctrlF7Forward.rawValue)
        let ctrlF8Status = isHotkeyRegistered(id: HotkeyID.ctrlF8Forward.rawValue)
        let ctrlF9Status = isHotkeyRegistered(id: HotkeyID.ctrlF9Forward.rawValue)
        let ctrlF10Status = isHotkeyRegistered(id: HotkeyID.ctrlF10Forward.rawValue)
        let ctrlF11Status = isHotkeyRegistered(id: HotkeyID.ctrlF11Forward.rawValue)
        let ctrlF12Status = isHotkeyRegistered(id: HotkeyID.ctrlF12Forward.rawValue)
        
        status += "F1 (Toggle Browsers): \(f1Status ? "Registered" : "Failed")\n"
        status += "F2 (Toggle Editors): \(f2Status ? "Registered" : "Failed")\n"
        status += "F3 (Toggle Terminals): \(f3Status ? "Registered" : "Failed")\n"
        status += "Cmd+F1 (Cycle Browsers): \(cmdF1Status ? "Registered" : "Failed")\n"
        status += "Cmd+F2 (Cycle Editors): \(cmdF2Status ? "Registered" : "Failed")\n"
        status += "Cmd+F3 (Cycle Terminals): \(cmdF3Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F1 (Forward F1): \(ctrlF1Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F2 (Forward F2): \(ctrlF2Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F3 (Forward F3): \(ctrlF3Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F4 (Forward F4): \(ctrlF4Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F5 (Forward F5): \(ctrlF5Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F6 (Forward F6): \(ctrlF6Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F7 (Forward F7): \(ctrlF7Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F8 (Forward F8): \(ctrlF8Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F9 (Forward F9): \(ctrlF9Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F10 (Forward F10): \(ctrlF10Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F11 (Forward F11): \(ctrlF11Status ? "Registered" : "Failed")\n"
        status += "Ctrl+F12 (Forward F12): \(ctrlF12Status ? "Registered" : "Failed")\n"
        
        return status
    }
}
