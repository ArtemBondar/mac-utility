import Foundation

/// Tests the real host request handler without creating UI or launching Terminal.
@main
struct FinderTerminalActionTests {
    @MainActor
    static func main() throws {
        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent("Finder terminal ü \(UUID())", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: folder) }
        let file = folder.appendingPathComponent("item.txt")
        guard fm.createFile(atPath: file.path, contents: Data()) else { fatalError("Could not create test file") }
        let expected = FinderTargetResolver.canonicalFileURL(folder)!
        let name = "MacUtility.TerminalActionTests.\(UUID())"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = SettingsStore(defaults: defaults)

        for (context, target, selection) in [("container", folder, Optional<URL>.none),
                                              ("item", folder, Optional(file))] {
            var parts = URLComponents()
            parts.scheme = FinderActionRequest.scheme
            parts.host = "action"
            parts.queryItems = [URLQueryItem(name: "action", value: "openTerminal"),
                                URLQueryItem(name: "context", value: context),
                                URLQueryItem(name: "target", value: target.absoluteString)]
            if let selection { parts.queryItems?.append(URLQueryItem(name: "selection", value: selection.absoluteString)) }
            var launched = false
            FinderRequestHandler.handle(parts.url!, store: store) { destination, completion in
                precondition(destination == expected)
                launched = true
                completion(.success(()))
            }
            precondition(launched, "Finder Terminal actions must launch without a confirmation step")
        }
        print("PASS: Finder Terminal actions launch immediately for background and item contexts")
    }
}
