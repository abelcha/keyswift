import Cocoa
import KeyShift
import Foundation

class LogWindowController: NSWindowController {
    let textView: NSTextView
    
    init() {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyShift Logs"
        window.setFrameAutosaveName("LogWindow")
        
        // Create scroll view
        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        
        // Create text view
        textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        // Set up scroll view
        scrollView.documentView = textView
        window.contentView?.addSubview(scrollView)
        
        super.init(window: window)
        
        // Listen for log messages
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.example.KeyShift.log"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let message = notification.userInfo?["message"] as? String {
                self?.appendLog(message)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)\n"
        
        textView.textStorage?.append(NSAttributedString(string: logEntry))
        textView.scrollToEndOfDocument(nil)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: LogWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = LogWindowController()
        windowController?.showWindow(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Create and configure application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
