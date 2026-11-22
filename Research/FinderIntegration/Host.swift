import AppKit

// A diagnostic-only Services provider. It never modifies the selected files.
final class ServiceProvider: NSObject {
    @objc func inspect(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard !urls.isEmpty else {
            error.pointee = "No file URLs were supplied." as NSString
            return
        }
        let alert = NSAlert()
        alert.messageText = "Services prototype received \(urls.count) item(s)"
        alert.informativeText = urls.map(\.path).joined(separator: "\n")
        alert.runModal()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let provider = ServiceProvider()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
