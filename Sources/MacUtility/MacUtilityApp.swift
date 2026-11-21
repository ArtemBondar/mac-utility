import SwiftUI

@main
struct MacUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Mac Utility", systemImage: "folder.badge.gearshape") {
            Text("Finder integration: prototype only")
                .disabled(true)
            Divider()
            Button("About Mac Utility") { NSApp.orderFrontStandardAboutPanel(nil) }
            Button("Quit Mac Utility") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
