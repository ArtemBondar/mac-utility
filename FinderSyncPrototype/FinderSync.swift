import Cocoa
import FinderSync

// Research prototype only. This file is not part of the Swift package or an
// installable extension. Finder Sync is designed for file synchronization apps.
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Temporary, intentionally narrow scope for a local feasibility test.
        // A production implementation needs user-selected folders and permissions.
        FIFinderSyncController.default().directoryURLs = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("MacUtilityPrototype", isDirectory: true)
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else {
            return nil
        }
        let menu = NSMenu(title: "Mac Utility")
        let item = NSMenuItem(title: "Mac Utility prototype", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
        return menu
    }
}
