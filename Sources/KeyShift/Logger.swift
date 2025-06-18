import Foundation

public class Logger {
    public static let shared = Logger()
    private let center = DistributedNotificationCenter.default()
    
    private init() {}
    
    public func log(_ message: String) {
        // Send log message via distributed notification
        center.postNotificationName(
            NSNotification.Name("com.example.KeyShift.log"),
            object: nil,
            userInfo: ["message": message],
            deliverImmediately: true
        )
        
        // Also print to console for terminal output
        print(message)
    }
}
