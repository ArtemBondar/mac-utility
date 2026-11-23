import Foundation
import Combine

struct SavedFolder: Codable, Identifiable, Equatable {
    var id: UUID
    var path: String
    var bookmark: Data
}

struct StoredSettings: Codable, Equatable {
    var folders: [SavedFolder] = []
    var newFile = true
    var newFolder = true
    var openTerminal = true
}

final class SettingsStore: ObservableObject {
    @Published private(set) var settings: StoredSettings
    @Published private(set) var showDockIcon: Bool
    private let defaults: UserDefaults
    private let sharedDefaults: UserDefaults?
    private let key = "settings.v1"
    #if DIRECT_DISTRIBUTION
    private var configurationObserver: NSObjectProtocol?
    #endif

    init(defaults: UserDefaults = .standard, sharedDefaults: UserDefaults? = nil) {
        self.defaults = defaults
        self.sharedDefaults = sharedDefaults
        self.showDockIcon = defaults.bool(forKey: "showDockIcon")
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode(StoredSettings.self, from: data) {
            settings = saved
        } else {
            settings = StoredSettings()
        }
        #if DIRECT_DISTRIBUTION
        configurationObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(FinderConfiguration.requestNotification), object: nil, queue: .main
        ) { [weak self] _ in self?.publishFinderConfiguration() }
        #endif
        publishFinderConfiguration()
    }

    func setShowDockIcon(_ visible: Bool) {
        showDockIcon = visible
        defaults.set(visible, forKey: "showDockIcon")
    }

    func setActions(newFile: Bool, newFolder: Bool, openTerminal: Bool) {
        settings.newFile = newFile
        settings.newFolder = newFolder
        settings.openTerminal = openTerminal
        save()
    }

    func addFolder(_ url: URL) throws {
        let path = url.standardizedFileURL.path
        guard !settings.folders.contains(where: { $0.path == path }) else { return }
        let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        settings.folders.append(SavedFolder(id: UUID(), path: path, bookmark: bookmark))
        save()
    }

    func removeFolder(id: UUID) {
        settings.folders.removeAll { $0.id == id }
        save()
    }

    // Resolve only in the containing app; bookmark sharing with an extension is a separate task.
    func checkFolder(_ folder: SavedFolder) -> Bool {
        do {
            var stale = false
            let url = try URL(resolvingBookmarkData: folder.bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            guard granted, Self.isDirectory(at: url) else { return false }
            if stale {
                let renewed = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                if let index = settings.folders.firstIndex(where: { $0.id == folder.id }) {
                    settings.folders[index].bookmark = renewed
                    settings.folders[index].path = url.path
                    save()
                }
            }
            return true
        } catch { return false }
    }

    static func isDirectory(at url: URL) -> Bool {
        var directory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &directory) && directory.boolValue
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: key) }
        publishFinderConfiguration()
    }

    private func publishFinderConfiguration() {
        let config = FinderConfiguration(roots: FinderConfiguration.defaultRoots ?? settings.folders.map(\.path), newFile: settings.newFile,
                                         newFolder: settings.newFolder, openTerminal: settings.openTerminal)
        #if DIRECT_DISTRIBUTION
        guard let data = try? JSONEncoder().encode(config) else { return }
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(FinderConfiguration.notification),
            object: nil, userInfo: [FinderConfiguration.notificationDataKey: data], deliverImmediately: true)
        #else
        guard let shared = sharedDefaults else { return }
        guard (try? config.write(to: shared)) != nil else { return }
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(FinderConfiguration.notification),
                                                                       object: nil, userInfo: nil, deliverImmediately: true)
        #endif
    }
}
