import Cocoa
import FinderSync
import OSLog

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "com.example.MacUtility", category: "FinderAction")
    private let defaults = UserDefaults(suiteName: FinderConfiguration.groupIdentifier)
    private var config: FinderConfiguration?

    override init() {
        super.init()
        reload()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(changed(_:)),
            name: Notification.Name(FinderConfiguration.notification), object: nil
        )
        #if DIRECT_DISTRIBUTION
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(FinderConfiguration.requestNotification), object: nil, userInfo: nil, deliverImmediately: true)
        #endif
    }

    @objc private func changed(_ notification: Notification) {
        #if DIRECT_DISTRIBUTION
        guard let data = notification.userInfo?[FinderConfiguration.notificationDataKey] as? Data,
              let received = FinderConfiguration.directNotificationConfiguration(data) else { return }
        config = received
        FIFinderSyncController.default().directoryURLs = Set(received.roots.map { URL(fileURLWithPath: $0, isDirectory: true) })
        #else
        reload()
        #endif
    }

    private func reload() {
        config = defaults.flatMap(FinderConfiguration.read(from:))
        #if DIRECT_DISTRIBUTION
        // Always register the broad root even before the host first launches.
        // The host independently enforces preferences and OS permissions.
        if config == nil {
            config = FinderConfiguration(roots: ["/"], newFile: true, newFolder: true, openTerminal: true)
        }
        #endif
        FIFinderSyncController.default().directoryURLs = Set((config?.roots ?? []).map {
            URL(fileURLWithPath: $0, isDirectory: true)
        })
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard let config else { return nil }
        let context: FinderMenuAction.Context
        switch menuKind {
        case .contextualMenuForItems: context = .item
        case .contextualMenuForContainer: context = .container
        default: return nil
        }
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        guard context != .item || selected.count == 1 else { return nil }
        let target = controller.targetedURL()
        guard context != .container || target != nil else { return nil }
        let menu = NSMenu(title: "")
        func add(_ key: String, _ action: FinderMenuAction.Action, _ enabled: Bool) {
            guard enabled else { return }
            let title = Bundle(for: FinderSync.self).localizedString(forKey: key, value: key, table: nil)
            let selector: Selector
            switch (action, context) {
            case (.newFile, .item): selector = #selector(newFileForItem(_:))
            case (.newFile, .container): selector = #selector(newFileInContainer(_:))
            case (.newFolder, .item): selector = #selector(newFolderForItem(_:))
            case (.newFolder, .container): selector = #selector(newFolderInContainer(_:))
            case (.openTerminal, .item): selector = #selector(openTerminalForItem(_:))
            case (.openTerminal, .container): selector = #selector(openTerminalInContainer(_:))
            }
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        add("New File", .newFile, config.newFile)
        add("New Folder", .newFolder, config.newFolder)
        add("Open Terminal Here", .openTerminal, config.openTerminal)
        let pathTitle = Bundle(for: FinderSync.self).localizedString(forKey: "Copy Folder Path", value: "Copy Folder Path", table: nil)
        let pathAction: Selector = context == .item ? #selector(copyPathForItem(_:)) : #selector(copyPathInContainer(_:))
        let pathItem = NSMenuItem(title: pathTitle, action: pathAction, keyEquivalent: "")
        pathItem.target = self
        menu.addItem(pathItem)
        return menu.items.isEmpty ? nil : menu
    }

    @objc private func copyPathForItem(_ sender: Any?) { copyFolderPath(in: .item) }
    @objc private func copyPathInContainer(_ sender: Any?) { copyFolderPath(in: .container) }

    private func copyFolderPath(in context: FinderMenuAction.Context) {
        let controller = FIFinderSyncController.default()
        let copied = FinderMenuAction.copyFolderPath(context: context, target: controller.targetedURL(),
                                                      selection: controller.selectedItemURLs() ?? []) { path in
            NSPasteboard.general.clearContents()
            return NSPasteboard.general.setString(path, forType: .string)
        }
        if !copied { logger.error("Could not copy the Finder folder path") }
    }

    @objc private func newFileForItem(_ sender: Any?) { perform(.newFile, in: .item) }
    @objc private func newFileInContainer(_ sender: Any?) { perform(.newFile, in: .container) }
    @objc private func newFolderForItem(_ sender: Any?) { perform(.newFolder, in: .item) }
    @objc private func newFolderInContainer(_ sender: Any?) { perform(.newFolder, in: .container) }
    @objc private func openTerminalForItem(_ sender: Any?) { perform(.openTerminal, in: .item) }
    @objc private func openTerminalInContainer(_ sender: Any?) { perform(.openTerminal, in: .container) }

    // Finder invokes the selector across processes. Its sender can differ
    // from the menu item that the extension constructed.
    private func perform(_ action: FinderMenuAction.Action, in context: FinderMenuAction.Context) {
        #if DIRECT_DISTRIBUTION
        let scheme = "macutility-finder-direct"
        #else
        let scheme = "macutility-finder"
        #endif
        let controller = FIFinderSyncController.default()
        logger.notice("Finder invoked a menu action")
        guard let url = FinderMenuAction.requestURL(action: action, context: context, target: controller.targetedURL(),
                                                    selection: controller.selectedItemURLs() ?? [], scheme: scheme) else {
            logger.error("Finder action did not have a valid target")
            return
        }
        if NSWorkspace.shared.open(url) {
            logger.notice("Launch Services accepted the Finder action")
        } else {
            logger.error("Launch Services rejected the Finder action")
        }
    }
}
