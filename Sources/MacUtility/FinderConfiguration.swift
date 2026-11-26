import Foundation

/// Shared configuration contains paths and preferences only, never security bookmarks.
struct FinderConfiguration: Codable, Equatable {
    var roots: [String]
    var newFile: Bool
    var newFolder: Bool
    var openTerminal: Bool
    var copyFolderPath: Bool

    init(roots: [String], newFile: Bool, newFolder: Bool, openTerminal: Bool, copyFolderPath: Bool = true) {
        self.roots = roots
        self.newFile = newFile
        self.newFolder = newFolder
        self.openTerminal = openTerminal
        self.copyFolderPath = copyFolderPath
    }

    private enum CodingKeys: String, CodingKey { case roots, newFile, newFolder, openTerminal, copyFolderPath }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        roots = try values.decode([String].self, forKey: .roots)
        newFile = try values.decode(Bool.self, forKey: .newFile)
        newFolder = try values.decode(Bool.self, forKey: .newFolder)
        openTerminal = try values.decode(Bool.self, forKey: .openTerminal)
        copyFolderPath = try values.decodeIfPresent(Bool.self, forKey: .copyFolderPath) ?? true
    }

    #if DIRECT_DISTRIBUTION
    // The direct-download build is not sandboxed; this is an ordinary shared
    // preferences domain, not an App Group or a filesystem grant.
    static let groupIdentifier = "com.example.MacUtilityDirect.finder"
    static let defaultRoots: [String]? = ["/"]
    #else
    static let groupIdentifier = "group.com.example.MacUtility"
    static let defaultRoots: [String]? = nil
    #endif
    static let key = "finder.configuration.v1"
    static let notification = "com.example.MacUtility.finderConfigurationChanged"
    static let requestNotification = "com.example.MacUtility.finderConfigurationRequested"
    static let notificationDataKey = "configuration"

    static func directNotificationConfiguration(_ data: Data) -> FinderConfiguration? {
        guard var configuration = try? JSONDecoder().decode(FinderConfiguration.self, from: data) else { return nil }
        // Distributed notifications are unauthenticated; never trust supplied roots.
        configuration.roots = ["/"]
        return configuration
    }

    static func read(from defaults: UserDefaults) -> FinderConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FinderConfiguration.self, from: data)
    }

    func write(to defaults: UserDefaults) throws {
        defaults.set(try JSONEncoder().encode(self), forKey: Self.key)
    }
}
