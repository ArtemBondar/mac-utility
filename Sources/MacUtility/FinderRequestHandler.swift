import AppKit

/// URL scheme requests can originate from any application. Every request is
/// checked against the current preferences and an active user-granted scope.
@MainActor
enum FinderRequestHandler {
    static func handle(_ url: URL, store: SettingsStore) {
        guard let request = FinderActionRequest.parse(url), enabled(request.action, settings: store.settings) else {
            unavailable(); return
        }
        for folder in store.settings.folders {
            var stale = false
            guard let root = try? URL(resolvingBookmarkData: folder.bookmark,
                                      options: [.withSecurityScope, .withoutUI],
                                      relativeTo: nil, bookmarkDataIsStale: &stale), !stale,
                  root.startAccessingSecurityScopedResource() else { continue }
            let canonicalRoot = root.standardizedFileURL.resolvingSymlinksInPath()
            let context: FinderTargetResolver.Context = request.context == .item ? .item : .container
            guard let destination = FinderTargetResolver.resolve(context: context, target: request.target, selection: request.selection),
                  let directory = SecureDirectory.open(root: canonicalRoot, destination: destination) else {
                root.stopAccessingSecurityScopedResource()
                continue
            }
            NSApp.activate(ignoringOtherApps: true)
            switch request.action {
            case .newFile, .newFolder:
                let kind: FileCreation.Kind = request.action == .newFile ? .file : .folder
                CreationPrompt.show(kind: kind, in: destination, directoryFD: directory.descriptor)
                root.stopAccessingSecurityScopedResource()
            case .openTerminal:
                let confirmation = NSAlert()
                confirmation.messageText = L10n.format("Open Terminal in %@?", destination.path)
                confirmation.addButton(withTitle: L10n.text("Open Terminal"))
                confirmation.addButton(withTitle: L10n.text("Cancel"))
                guard confirmation.runModal() == .alertFirstButtonReturn else {
                    root.stopAccessingSecurityScopedResource(); return
                }
                TerminalLauncher.open(destination) { result in
                    // Retain the opened directory and the scope until the handoff finishes.
                    _ = directory
                    root.stopAccessingSecurityScopedResource()
                    if case .failure(let error) = result {
                        DispatchQueue.main.async { NSAlert(error: error).runModal() }
                    }
                }
            }
            return
        }
        unavailable()
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
        alert.messageText = L10n.text("Finder action is unavailable. Check the selected folder and its access in Settings.")
        alert.runModal()
    }
}
