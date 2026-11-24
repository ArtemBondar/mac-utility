import Foundation

/// Retains the same window controller even if AppKit orders its window out.
final class SettingsWindowOwner<Controller: AnyObject> {
    private var controller: Controller?

    func getOrCreate(_ make: () -> Controller) -> Controller {
        if let controller { return controller }
        let created = make()
        controller = created
        return created
    }
}

/// Changing AppKit's activation policy can order out the Settings window.
/// Restore the retained controller after the transition.
enum DockVisibility {
    static func change(_ visible: Bool,
                       setPolicy: (Bool) -> Void,
                       reopenSettings: @escaping () -> Void,
                       schedule: (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute: $0) }) {
        setPolicy(visible)
        schedule(reopenSettings)
    }
}
