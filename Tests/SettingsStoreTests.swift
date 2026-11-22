import Foundation

@main
struct SettingsStoreTests {
    static func main() throws {
        let name = "MacUtilityTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else { fatalError("Cannot create isolated defaults") }
        defer { defaults.removePersistentDomain(forName: name) }
        let store = SettingsStore(defaults: defaults)
        precondition(store.settings.newFile && store.settings.newFolder && store.settings.openTerminal)
        store.setActions(newFile: false, newFolder: true, openTerminal: false)
        let reloaded = SettingsStore(defaults: defaults)
        precondition(!reloaded.settings.newFile && reloaded.settings.newFolder && !reloaded.settings.openTerminal)
        let folder = SavedFolder(id: UUID(), path: "/tmp/example", bookmark: Data("invalid".utf8))
        var settings = reloaded.settings
        settings.folders = [folder]
        defaults.set(try JSONEncoder().encode(settings), forKey: "settings.v1")
        let saved = SettingsStore(defaults: defaults)
        precondition(saved.settings.folders == [folder])
        let groupName = "MacUtilitySharedTests.\(UUID().uuidString)"
        guard let shared = UserDefaults(suiteName: groupName) else { fatalError("Cannot create shared test defaults") }
        defer { shared.removePersistentDomain(forName: groupName) }
        let publishing = SettingsStore(defaults: defaults, sharedDefaults: shared)
        precondition(FinderConfiguration.read(from: shared)?.roots == [folder.path])
        precondition(FinderConfiguration.read(from: shared)?.newFile == false)
        publishing.setActions(newFile: true, newFolder: false, openTerminal: true)
        precondition(FinderConfiguration.read(from: shared)?.newFolder == false)
        publishing.removeFolder(id: folder.id)
        precondition(FinderConfiguration.read(from: shared)?.roots == [])
        // Configuration shared with the extension contains paths, never bookmark data.
        let sharedData = shared.data(forKey: FinderConfiguration.key)!
        precondition(!String(decoding: sharedData, as: UTF8.self).contains("bookmark"))
        precondition(!saved.checkFolder(folder), "Invalid bookmark must fail safely")
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("settings-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let file = temp.appendingPathComponent("file")
        try Data().write(to: file)
        precondition(SettingsStore.isDirectory(at: temp), "Existing folder must be accepted")
        precondition(!SettingsStore.isDirectory(at: file), "A file replacing a folder must be rejected")
        precondition(!SettingsStore.isDirectory(at: temp.appendingPathComponent("missing")), "Missing folder must be rejected")
        saved.removeFolder(id: folder.id)
        precondition(SettingsStore(defaults: defaults).settings.folders.isEmpty)
        defaults.set(Data("invalid JSON".utf8), forKey: "settings.v1")
        precondition(SettingsStore(defaults: defaults).settings == StoredSettings())
        print("PASS: settings defaults, persistence, removal and invalid bookmark handling")
    }
}
