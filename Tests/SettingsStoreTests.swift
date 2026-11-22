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
        precondition(!saved.checkFolder(folder), "Invalid bookmark must fail safely")
        saved.removeFolder(id: folder.id)
        precondition(SettingsStore(defaults: defaults).settings.folders.isEmpty)
        defaults.set(Data("invalid JSON".utf8), forKey: "settings.v1")
        precondition(SettingsStore(defaults: defaults).settings == StoredSettings())
        print("PASS: settings defaults, persistence, removal and invalid bookmark handling")
    }
}
