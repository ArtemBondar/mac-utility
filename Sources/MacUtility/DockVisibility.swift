import Foundation

/// Changing AppKit's activation policy can close the Settings scene. Reopen it
/// on the next run-loop turn after a user changes the Dock preference.
enum DockVisibility {
    static func change(_ visible: Bool,
                       setPolicy: (Bool) -> Void,
                       reopenSettings: @escaping () -> Void,
                       schedule: (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute: $0) }) {
        setPolicy(visible)
        schedule(reopenSettings)
    }
}
