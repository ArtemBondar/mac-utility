import Foundation

@main
struct SettingsStoreTests {
    static func main() throws {
        let name = "MacUtilityTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else { fatalError("Cannot create isolated defaults") }
        defer { defaults.removePersistentDomain(forName: name) }
        let store = SettingsStore(defaults: defaults)
        precondition(SettingsStore.shouldOfferFinderSetup(extensionEnabled: false, alreadyOffered: false))
        precondition(!SettingsStore.shouldOfferFinderSetup(extensionEnabled: true, alreadyOffered: false))
        precondition(!SettingsStore.shouldOfferFinderSetup(extensionEnabled: false, alreadyOffered: true))
        precondition(!store.showDockIcon, "Dock icon must default to hidden")
        store.setShowDockIcon(true)
        precondition(SettingsStore(defaults: defaults).showDockIcon, "Dock preference must persist")
        store.setShowDockIcon(false)
        precondition(!SettingsStore(defaults: defaults).showDockIcon, "Hidden Dock preference must persist")
        // Keep one controller alive across policy changes; SwiftUI scene handles
        // can become invalid when the operating system orders the window out.
        final class Controller {}
        let owner = SettingsWindowOwner<Controller>()
        weak var retained: Controller?
        do { retained = owner.getOrCreate { Controller() } }
        precondition(retained != nil, "Settings controller must be retained")
        var creations = 0
        let second = owner.getOrCreate { creations += 1; return Controller() }
        precondition(retained === second && creations == 0,
                     "Settings controller must be retained and reused")
        // Model AppKit closing the settings scene when the policy changes. The
        // deferred reopen must restore it for both directions of the toggle.
        for visible in [true, false] {
            var windowIsOpen = true
            var appliedPolicy: Bool?
            var pending: (() -> Void)?
            DockVisibility.change(visible, setPolicy: { newValue in
                appliedPolicy = newValue
                windowIsOpen = false
            }, reopenSettings: {
                windowIsOpen = true
            }, schedule: { pending = $0 })
            precondition(appliedPolicy == visible && !windowIsOpen)
            precondition(pending != nil, "Settings reopening must be scheduled")
            pending?()
            precondition(windowIsOpen, "Settings must be reopened after changing Dock visibility")
        }
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
