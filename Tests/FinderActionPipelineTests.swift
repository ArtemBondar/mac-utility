import Foundation

/// Exercises Finder request data through the direct-build filesystem pipeline.
/// macOS delivery and modal UI still require an interactive integration test.
@main
struct FinderActionPipelineTests {
    static func main() throws {
        let fileManager = FileManager.default
        let folder = fileManager.temporaryDirectory.appendingPathComponent("Finder action spaces ü \(UUID())", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: folder) }
        guard let canonical = FinderTargetResolver.canonicalFileURL(folder) else { fatalError("Cannot canonicalize test folder") }

        for action in [FinderActionRequest.Action.newFile, .newFolder, .openTerminal] {
            var parts = URLComponents()
            parts.scheme = FinderActionRequest.scheme
            parts.host = "action"
            parts.queryItems = [URLQueryItem(name: "action", value: action.rawValue),
                                URLQueryItem(name: "context", value: "container"),
                                URLQueryItem(name: "target", value: folder.absoluteString)]
            guard let url = parts.url, let request = FinderActionRequest.parse(url) else { fatalError("Finder request parse failed: \(String(describing: parts.url))") }
            guard let destination = FinderTargetResolver.resolve(context: .container, target: request.target, selection: request.selection) else { fatalError("Finder target resolution failed: \(String(describing: request.target))") }
            guard let directory = SecureDirectory.open(root: URL(fileURLWithPath: "/", isDirectory: true), destination: destination) else { fatalError("Secure directory open failed: \(destination)") }
            precondition(destination == canonical)
            switch request.action {
            case .newFile:
                let result = try FileCreation.create(.file, name: "created.txt", in: destination, directoryFD: directory.descriptor)
                precondition(fileManager.fileExists(atPath: result.path))
            case .newFolder:
                let result = try FileCreation.create(.folder, name: "created folder", in: destination, directoryFD: directory.descriptor)
                var isDirectory: ObjCBool = false
                precondition(fileManager.fileExists(atPath: result.path, isDirectory: &isDirectory) && isDirectory.boolValue)
            case .openTerminal:
                let terminal = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
                var called = false
                TerminalLauncher.open(destination, terminalURL: { terminal }, launch: { received, application, done in
                    precondition(received == canonical && application == terminal)
                    called = true
                    done(nil)
                }, completion: { result in
                    guard case .success = result else { fatalError("Terminal handoff failed") }
                })
                precondition(called)
            }
        }
        print("PASS: Finder request through direct filesystem action pipeline")
    }
}
