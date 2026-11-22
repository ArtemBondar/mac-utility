import Foundation

/// Shared configuration contains paths and preferences only, never security bookmarks.
struct FinderConfiguration: Codable, Equatable {
    var roots: [String]
    var newFile: Bool
    var newFolder: Bool
    var openTerminal: Bool

    static let groupIdentifier = "group.com.example.MacUtility"
    static let key = "finder.configuration.v1"
    static let notification = "com.example.MacUtility.finderConfigurationChanged"

    static func read(from defaults: UserDefaults) -> FinderConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FinderConfiguration.self, from: data)
    }

    func write(to defaults: UserDefaults) throws {
        defaults.set(try JSONEncoder().encode(self), forKey: Self.key)
    }
}
