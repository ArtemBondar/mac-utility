import AppKit

/// UI entry point for a future Finder action. The caller must hold folder access.
@MainActor
enum CreationPrompt {
    static func show(kind: FileCreation.Kind, in directory: URL) {
        let isFile = kind == .file
        let alert = NSAlert()
        alert.messageText = isFile ? "New File" : "New Folder"
        alert.informativeText = "Enter a name for the new item."
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.placeholderString = isFile ? "File name" : "Folder name"
        alert.accessoryView = input
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        while alert.runModal() == .alertFirstButtonReturn {
            do {
                _ = try FileCreation.create(kind, name: input.stringValue, in: directory)
                return
            } catch {
                let failure = NSAlert(error: error)
                failure.runModal()
            }
        }
    }
}
