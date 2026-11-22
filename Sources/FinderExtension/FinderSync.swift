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
    }

    @objc private func changed(_ notification: Notification) { reload() }

    private func reload() {
        config = defaults.flatMap(FinderConfiguration.read(from:))
        FIFinderSyncController.default().directoryURLs = Set((config?.roots ?? []).map {
            URL(fileURLWithPath: $0, isDirectory: true)
        })
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard let config else { return nil }
        let context: String
        switch menuKind {
        case .contextualMenuForItems: context = "item"
        case .contextualMenuForContainer: context = "container"
        default: return nil
        }
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        guard context != "item" || selected.count == 1 else { return nil }
        let target = controller.targetedURL()
        guard context != "container" || target != nil else { return nil }
        let menu = NSMenu(title: "")
        func add(_ key: String, _ action: String, _ enabled: Bool) {
            guard enabled else { return }
            var components = URLComponents()
            components.scheme = "macutility-finder"
            components.host = "action"
            components.queryItems = [URLQueryItem(name: "action", value: action), URLQueryItem(name: "context", value: context)]
            if let target { components.queryItems?.append(URLQueryItem(name: "target", value: target.absoluteString)) }
            if context == "item" {
                components.queryItems?.append(contentsOf: selected.map { URLQueryItem(name: "selection", value: $0.absoluteString) })
            }
            guard let url = components.url else { return }
            let title = Bundle(for: FinderSync.self).localizedString(forKey: key, value: key, table: nil)
            let item = NSMenuItem(title: title, action: #selector(performAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = url
            menu.addItem(item)
        }
        add("New File", "newFile", config.newFile)
        add("New Folder", "newFolder", config.newFolder)
        add("Open Terminal Here", "openTerminal", config.openTerminal)
        return menu.items.isEmpty ? nil : menu
    }

    @objc private func performAction(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }
}
