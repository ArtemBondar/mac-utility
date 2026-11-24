import AppKit

/// UI entry point for a future Finder action. The caller must hold folder access.
@MainActor
enum CreationPrompt {
    static func show(kind: FileCreation.Kind, in directory: URL, directoryFD: Int32? = nil) {
        let isFile = kind == .file
        let alert = NSAlert()
        alert.messageText = isFile ? L10n.text("New File") : L10n.text("New Folder")
        alert.informativeText = L10n.format("Enter a name for the new item in %@.", directory.path)
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.placeholderString = isFile ? L10n.text("File name") : L10n.text("Folder name")
        alert.accessoryView = input
        alert.addButton(withTitle: L10n.text("Create"))
        alert.addButton(withTitle: L10n.text("Cancel"))
        while alert.runModal() == .alertFirstButtonReturn {
            do {
                if let directoryFD {
                    _ = try FileCreation.create(kind, name: input.stringValue, in: directory, directoryFD: directoryFD)
                } else {
                    _ = try FileCreation.create(kind, name: input.stringValue, in: directory)
                }
                return
            } catch {
                let failure = NSAlert(error: error)
                failure.runModal()
            }
        }
    }
}
