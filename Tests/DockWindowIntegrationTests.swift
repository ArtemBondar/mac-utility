import AppKit
import Foundation

// Run in a logged-in graphical session: this exercises AppKit's real window
// ordering when the application's Dock visibility changes.
@main
struct DockWindowIntegrationTests {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let owner = SettingsWindowOwner<NSWindowController>()
        func showSettings() {
            let controller = owner.getOrCreate {
                let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
                                      styleMask: [.titled, .closable], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                return NSWindowController(window: window)
            }
            app.unhide(nil)
            app.activate(ignoringOtherApps: true)
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
        }
        showSettings()
        let controller = owner.getOrCreate { fatalError("window controller should exist") }
        for visible in [false, true, false] {
            var reopened = false
            DockVisibility.change(visible, setPolicy: { app.setActivationPolicy($0 ? .regular : .accessory) }, reopenSettings: {
                showSettings()
                reopened = true
            })
            let deadline = Date(timeIntervalSinceNow: 2)
            while !reopened && Date() < deadline {
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            }
            precondition(reopened, "Settings restoration did not run")
            // Allow AppKit to finish processing the policy transition before
            // checking, so a later window-ordering event is also observed.
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
            precondition(controller.window?.isVisible == true, "Settings window must remain visible after changing Dock visibility")
            precondition(owner.getOrCreate { fatalError("controller recreated") } === controller)
        }
        controller.close()
        print("PASS: Settings window remains visible across Dock visibility changes")
    }
}
