import Cocoa
import Carbon

public class HotkeyManager {
    private let windowManager: WindowManager
    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotkeys: [Int: EventHotKeyRef?] = [:]
    
    // Dynamic hotkey IDs based on config
    private var hotkeyIDCounter = 1
    private var fnKeyToHotkeyID: [Int: (toggle: Int, cycle: Int)] = [:]
    private var hotkeyIDToAction: [Int: HotkeyAction] = [:]
    
    private enum HotkeyAction {
        case toggleGroup(fnKey: Int)
        case cycleGroup(fnKey: Int)
        case forwardFunctionKey(fnKey: Int)
        case previousWindow
    }
    
    public init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    public func registerHotkeys() {
        // Register for hotkey events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Install event handler
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                guard let event = event else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
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
            return
        }
        
        // Register hotkeys dynamically based on WindowManager configuration
        registerConfigBasedHotkeys()
        
        // Register Control+Function key forwarding hotkeys (F1-F12)
        registerControlFunctionKeyForwarding()
        
        // Register Cmd+Escape for previous window
        let cmdEscapeID = getNextHotkeyID()
        hotkeyIDToAction[cmdEscapeID] = .previousWindow
        registerHotkey(
            id: cmdEscapeID,
            key: UInt32(kVK_Escape),
            modifiers: UInt32(cmdKey),
            name: "Cmd+Escape (Previous Window)"
        )
        
        print("HotkeyManager: Registered \(registeredHotkeys.count) hotkeys successfully")
    }
    
    private func registerConfigBasedHotkeys() {
        // Get function key mappings from WindowManager
        let fnKeyMappings = windowManager.getFnKeyMappings()
        
        for (fnKey, groupId) in fnKeyMappings {
            let toggleID = getNextHotkeyID()
            let cycleID = getNextHotkeyID()
            
            fnKeyToHotkeyID[fnKey] = (toggle: toggleID, cycle: cycleID)
            hotkeyIDToAction[toggleID] = .toggleGroup(fnKey: fnKey)
            hotkeyIDToAction[cycleID] = .cycleGroup(fnKey: fnKey)
            
            // Register F-key for toggle
            registerHotkey(
                id: toggleID,
                key: getFunctionKeyCode(fnKey),
                modifiers: 0,
                name: "F\(fnKey) (Toggle \(groupId.capitalized))"
            )
            
            // Register Cmd+F-key for cycle
            registerHotkey(
                id: cycleID,
                key: getFunctionKeyCode(fnKey),
                modifiers: UInt32(cmdKey),
                name: "Cmd+F\(fnKey) (Cycle \(groupId.capitalized))"
            )
        }
    }
    
    private func registerControlFunctionKeyForwarding() {
        let functionKeys = [kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6,
                           kVK_F7, kVK_F8, kVK_F9, kVK_F10, kVK_F11, kVK_F12]
        
        for (index, keyCode) in functionKeys.enumerated() {
            let fnKey = index + 1
            let forwardID = getNextHotkeyID()
            hotkeyIDToAction[forwardID] = .forwardFunctionKey(fnKey: fnKey)
            
            registerHotkey(
                id: forwardID,
                key: UInt32(keyCode),
                modifiers: UInt32(controlKey),
                name: "Ctrl+F\(fnKey) (Forward F\(fnKey))"
            )
        }
    }
    
    private func getNextHotkeyID() -> Int {
        let id = hotkeyIDCounter
        hotkeyIDCounter += 1
        return id
    }
    
    private func getFunctionKeyCode(_ fnKey: Int) -> UInt32 {
        switch fnKey {
        case 1: return UInt32(kVK_F1)
        case 2: return UInt32(kVK_F2)
        case 3: return UInt32(kVK_F3)
        case 4: return UInt32(kVK_F4)
        case 5: return UInt32(kVK_F5)
        case 6: return UInt32(kVK_F6)
        case 7: return UInt32(kVK_F7)
        case 8: return UInt32(kVK_F8)
        case 9: return UInt32(kVK_F9)
        case 10: return UInt32(kVK_F10)
        case 11: return UInt32(kVK_F11)
        case 12: return UInt32(kVK_F12)
        default: return UInt32(kVK_F1)
        }
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
            // Failed to register hotkey
        } else {
            // Successfully registered hotkey
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
            return
        }
        
        let id = Int(hotkeyID.id)
        
        guard let action = hotkeyIDToAction[id] else {
            return
        }
        
        DispatchQueue.main.async {
            switch action {
            case .toggleGroup(let fnKey):
                self.windowManager.toggleWindowsForFnKey(fnKey)
            case .cycleGroup(let fnKey):
                self.windowManager.cycleWindowsForFnKey(fnKey)
            case .forwardFunctionKey(let fnKey):
                let keyCode = self.getFunctionKeyCode(fnKey)
                self.sendFunctionKey(Int(keyCode))
            case .previousWindow:
                self.windowManager.switchToPreviousNonStandardWindow()
            }
        }
    }
    
    // Send a function key event programmatically
    private func sendFunctionKey(_ keyCode: Int) {
        let source = CGEventSource(stateID: .privateState)
        
        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true) else {
            return
        }
        
        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
            return
        }
        
        print("HotkeyManager: Sending function key \(keyCode)")
        // Set the event to be sent to the active application
        keyDownEvent.setIntegerValueField(.eventSourceUserData, value: 1)
        keyUpEvent.setIntegerValueField(.eventSourceUserData, value: 1)
        
        // Post the events to the active application
        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
}
