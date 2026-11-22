import AppKit

/// Call only while the app holds the required access to the directory.
enum TerminalLauncher {
    enum Failure: LocalizedError {
        case invalidFolder
        case terminalUnavailable
        case launchFailed

        var errorDescription: String? {
            switch self {
            case .invalidFolder: return L10n.text("The destination folder is unavailable.")
            case .terminalUnavailable: return L10n.text("Terminal could not be found.")
            case .launchFailed: return L10n.text("Terminal could not be opened.")
            }
        }
    }

    /// The completion reports whether Launch Services accepted the request. It does
    /// not prove the shell's working directory; verify that separately in Finder.
    static func open(_ directory: URL, workspace: NSWorkspace = .shared,
                     completion: @escaping (Result<Void, Failure>) -> Void) {
        open(directory, terminalURL: { workspace.urlForApplication(withBundleIdentifier: "com.apple.Terminal") },
             launch: { folder, app, done in
                 workspace.open([folder], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                     done(error)
                 }
             }, completion: completion)
    }

    static func open(_ directory: URL, terminalURL: () -> URL?,
                     launch: (URL, URL, @escaping (Error?) -> Void) -> Void,
                     completion: @escaping (Result<Void, Failure>) -> Void) {
        guard directory.isFileURL,
              let values = try? directory.resourceValues(forKeys: [.isDirectoryKey, .volumeIsLocalKey]),
              values.isDirectory == true, values.volumeIsLocal == true else {
            completion(.failure(.invalidFolder)); return
        }
        guard let app = terminalURL() else {
            completion(.failure(.terminalUnavailable)); return
        }
        launch(directory, app) { error in
            completion(error == nil ? .success(()) : .failure(.launchFailed))
        }
    }
}
