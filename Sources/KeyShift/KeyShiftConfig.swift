import Foundation
import Yams

public enum ConfigError: Error {
    case fileNotFound(String)
    case invalidYAML(String)
    case missingSection(String)
    case invalidFormat(String)
}

public struct KeyShiftConfig {
    public let appGroups: [AppGroup]
    public let groupsByFnKey: [Int: AppGroup]
    public let groupsById: [String: AppGroup]
    

    
    public static func loadConfig() throws -> KeyShiftConfig {
        print("[KeyShiftConfig] 🔄 Loading configuration...")
        
        // Determine XDG config directory
        let xdgConfigHome: String
        if let envXdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            xdgConfigHome = envXdgConfigHome
            print("[KeyShiftConfig] 📁 Using XDG_CONFIG_HOME: \(xdgConfigHome)")
        } else {
            // Fallback to ~/.config when XDG_CONFIG_HOME is not set
            let homeDir = NSString(string: "~").expandingTildeInPath
            xdgConfigHome = "\(homeDir)/.config"
            print("[KeyShiftConfig] 📁 XDG_CONFIG_HOME not set, using default: \(xdgConfigHome)")
        }
        
        let configPath = "\(xdgConfigHome)/keyshift.yaml"
        
        guard FileManager.default.fileExists(atPath: configPath) else {
            print("[KeyShiftConfig] ❌ Config not found at: \(configPath)")
            throw ConfigError.fileNotFound(configPath)
        }
        
        print("[KeyShiftConfig] ✅ Loading from: \(configPath)")
        return try loadFromFile(configPath)
    }
    

    


    
    private static func loadFromFile(_ path: String) throws -> KeyShiftConfig {
        let yamlString = try String(contentsOfFile: path)
        return try parseConfig(from: yamlString)
    }
    
    private static func parseConfig(from yamlString: String) throws -> KeyShiftConfig {
        guard let yamlData = try? Yams.load(yaml: yamlString) as? [String: Any] else {
            throw ConfigError.invalidYAML("Invalid YAML format in configuration")
        }
        
        guard let groupsData = yamlData["groups"] as? [String: [String: Any]] else {
            throw ConfigError.missingSection("Missing or invalid 'groups' section in configuration")
        }
        
        var appGroups: [AppGroup] = []
        var groupsByFnKey: [Int: AppGroup] = [:]
        var groupsById: [String: AppGroup] = [:]
        
        for (groupId, groupConfig) in groupsData {
            guard let bundleIds = groupConfig["bundle_ids"] as? [String] else {
                throw ConfigError.invalidFormat("Missing or invalid 'bundle_ids' for group '\(groupId)'")
            }
            
            guard let bindings = groupConfig["bindings"] as? [String: Int] else {
                throw ConfigError.invalidFormat("Missing or invalid 'bindings' for group '\(groupId)'")
            }
            
            guard let fnKey = bindings["fn_key"] else {
                throw ConfigError.invalidFormat("Missing 'fn_key' binding for group '\(groupId)'")
            }
            
            let group = AppGroup(id: groupId, bundleIDs: bundleIds, fnKey: fnKey)
            appGroups.append(group)
            groupsByFnKey[fnKey] = group
            groupsById[groupId] = group
        }
        
        if appGroups.isEmpty {
            throw ConfigError.invalidFormat("No valid groups found in configuration")
        }
        
        return KeyShiftConfig(
            appGroups: appGroups,
            groupsByFnKey: groupsByFnKey,
            groupsById: groupsById
        )
    }
}
