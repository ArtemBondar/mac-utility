import Cocoa
import FinderSync

// Diagnostic extension only; does not modify files or offer product features.
@objc(FinderSync)
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        if let root = ResearchRoot.currentUserURL() {
            FIFinderSyncController.default().directoryURLs = [root]
        }
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else { return nil }
        let menu = NSMenu(title: "Mac Utility Research")
        let item = NSMenuItem(title: "Inspect Finder Context", action: #selector(inspect(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        let controller = FIFinderSyncController.default()
        for line in ContextSummary.lines(target: controller.targetedURL(), selection: controller.selectedItemURLs() ?? []) {
            let detail = NSMenuItem(title: line, action: nil, keyEquivalent: "")
            detail.isEnabled = false
            menu.addItem(detail)
        }
        return menu
    }

    @objc private func inspect(_ sender: Any?) {
        let controller = FIFinderSyncController.default()
        let target = controller.targetedURL()?.path ?? "(no target)"
        let selection = controller.selectedItemURLs()?.map(\.path).joined(separator: "\n") ?? "(no selection)"
        let alert = NSAlert()
        alert.messageText = "Finder Sync prototype context"
        alert.informativeText = "Target: \(target)\nSelection:\n\(selection)"
        alert.runModal()
    }
}
