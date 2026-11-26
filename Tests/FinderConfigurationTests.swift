import Foundation

@main
struct FinderConfigurationTests {
    static func main() throws {
        #if DIRECT_DISTRIBUTION
        precondition(FinderConfiguration.defaultRoots == ["/"])
        precondition(!FinderConfiguration.groupIdentifier.hasPrefix("group."))
        #else
        precondition(FinderConfiguration.defaultRoots == nil)
        #endif
        let name = "MacUtility.ConfigurationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: name) else { fatalError("Unable to create test defaults") }
        defer { defaults.removePersistentDomain(forName: name) }
        precondition(FinderConfiguration.read(from: defaults) == nil)
        let config = FinderConfiguration(roots: ["/tmp/folder with space", "/tmp/other"], newFile: true,
                                         newFolder: false, openTerminal: true)
        let legacy = Data("""
        {"roots":["/tmp"],"newFile":false,"newFolder":true,"openTerminal":false}
        """.utf8)
        let migrated = try JSONDecoder().decode(FinderConfiguration.self, from: legacy)
        precondition(migrated.copyFolderPath && !migrated.newFile && migrated.newFolder && !migrated.openTerminal)
        let notification = FinderConfiguration.directNotificationConfiguration(try JSONEncoder().encode(config))
        precondition(notification?.roots == ["/"] && notification?.newFolder == false)
        precondition(FinderConfiguration.directNotificationConfiguration(Data("invalid".utf8)) == nil)
        try config.write(to: defaults)
        precondition(FinderConfiguration.read(from: defaults) == config)
        let replacement = FinderConfiguration(roots: [], newFile: false, newFolder: true, openTerminal: false, copyFolderPath: false)
        let disabledNotification = FinderConfiguration.directNotificationConfiguration(try JSONEncoder().encode(replacement))
        precondition(disabledNotification?.copyFolderPath == false)
        try replacement.write(to: defaults)
        precondition(FinderConfiguration.read(from: defaults) == replacement)
        defaults.set(Data("invalid".utf8), forKey: FinderConfiguration.key)
        precondition(FinderConfiguration.read(from: defaults) == nil)
        print("PASS: Finder shared configuration round trip and invalid data")
    }
}
