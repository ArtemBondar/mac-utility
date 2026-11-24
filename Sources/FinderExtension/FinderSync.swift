import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {
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
            let item = NSMenuItem(title: title, action: #selector(performAction(_:)), keyEquivalent: "")
            item.target = self
            item.tag = FinderMenuAction.tag(action: action, context: context)
            menu.addItem(item)
        }
        add("New File", .newFile, config.newFile)
        add("New Folder", .newFolder, config.newFolder)
        add("Open Terminal Here", .openTerminal, config.openTerminal)
        return menu.items.isEmpty ? nil : menu
    }

    @objc private func performAction(_ sender: NSMenuItem) {
        #if DIRECT_DISTRIBUTION
        let scheme = "macutility-finder-direct"
        #else
        let scheme = "macutility-finder"
        #endif
        let controller = FIFinderSyncController.default()
        guard let url = FinderMenuAction.requestURL(tag: sender.tag, target: controller.targetedURL(),
                                                     selection: controller.selectedItemURLs() ?? [], scheme: scheme) else { return }
        NSWorkspace.shared.open(url)
    }
}
