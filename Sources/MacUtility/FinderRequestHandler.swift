import AppKit

/// URL scheme requests can originate from any application. Every request is
/// checked against the current preferences and an active user-granted scope.
@MainActor
enum FinderRequestHandler {
    static func handle(_ url: URL, store: SettingsStore,
                       launchTerminal: @escaping (URL, @escaping (Result<Void, TerminalLauncher.Failure>) -> Void) -> Void = { directory, completion in
                           TerminalLauncher.open(directory, completion: completion)
                       }) {
        guard let request = FinderActionRequest.parse(url), enabled(request.action, settings: store.settings) else {
            unavailable(); return
        }
        #if DIRECT_DISTRIBUTION
        let context: FinderTargetResolver.Context = request.context == .item ? .item : .container
        guard let destination = FinderTargetResolver.resolve(context: context, target: request.target, selection: request.selection),
              let directory = SecureDirectory.open(root: URL(fileURLWithPath: "/", isDirectory: true), destination: destination) else {
            unavailable(); return
        }
        perform(request, destination: destination, directory: directory, releaseScope: {}, launchTerminal: launchTerminal)
        #else
        for folder in store.settings.folders {
            var stale = false
            guard let root = try? URL(resolvingBookmarkData: folder.bookmark,
                                      options: [.withSecurityScope, .withoutUI],
                                      relativeTo: nil, bookmarkDataIsStale: &stale), !stale,
                  root.startAccessingSecurityScopedResource() else { continue }
            guard let canonicalRoot = FinderTargetResolver.canonicalFileURL(root) else {
                root.stopAccessingSecurityScopedResource()
                continue
            }
            let context: FinderTargetResolver.Context = request.context == .item ? .item : .container
            guard let destination = FinderTargetResolver.resolve(context: context, target: request.target, selection: request.selection),
                  let directory = SecureDirectory.open(root: canonicalRoot, destination: destination) else {
                root.stopAccessingSecurityScopedResource()
                continue
            }
            perform(request, destination: destination, directory: directory, releaseScope: {
                root.stopAccessingSecurityScopedResource()
            }, launchTerminal: launchTerminal)
            return
        }
        unavailable()
        #endif
    }

    private static func perform(_ request: FinderActionRequest, destination: URL,
                                directory: SecureDirectory, releaseScope: @escaping () -> Void,
                                launchTerminal: @escaping (URL, @escaping (Result<Void, TerminalLauncher.Failure>) -> Void) -> Void) {
            switch request.action {
            case .newFile, .newFolder:
                NSApp.activate(ignoringOtherApps: true)
                let kind: FileCreation.Kind = request.action == .newFile ? .file : .folder
                CreationPrompt.show(kind: kind, in: destination, directoryFD: directory.descriptor)
                releaseScope()
            case .openTerminal:
                launchTerminal(destination) { result in
                    // Retain the opened directory and the scope until the handoff finishes.
                    _ = directory
                    releaseScope()
                    if case .failure(let error) = result {
                        DispatchQueue.main.async {
                            NSApp.activate(ignoringOtherApps: true)
                            NSAlert(error: error).runModal()
                        }
                    }
                }
            }
    }

    private static func enabled(_ action: FinderActionRequest.Action, settings: StoredSettings) -> Bool {
        switch action {
        case .newFile: return settings.newFile
        case .newFolder: return settings.newFolder
        case .openTerminal: return settings.openTerminal
        }
    }

    private static func unavailable() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        #if DIRECT_DISTRIBUTION
        alert.messageText = L10n.text("Finder action is unavailable. Check the selected location and macOS access permissions.")
        #else
        alert.messageText = L10n.text("Finder action is unavailable. Check the selected folder and its access in Settings.")
        #endif
        alert.runModal()
    }
}
