import Foundation

@main
struct FinderMenuActionTests {
    static func main() throws {
        let folder = URL(fileURLWithPath: "/tmp/A & Ж", isDirectory: true)
        let file = folder.appendingPathComponent("a #.txt")
        for action in FinderMenuAction.Action.allCases {
            for context in [FinderMenuAction.Context.item, .container] {
                guard let url = FinderMenuAction.requestURL(action: action, context: context, target: folder,
                    selection: context == .item ? [file] : [], scheme: FinderActionRequest.scheme),
                      let request = FinderActionRequest.parse(url) else { fatalError("Missing request") }
                let expected: FinderActionRequest.Action = action == .newFile ? .newFile : action == .newFolder ? .newFolder : .openTerminal
                precondition(request.action == expected && request.target == folder)
                precondition(request.context == (context == .item ? .item : .container))
                precondition(request.selection == (context == .item ? [file] : []))
            }
        }
        precondition(FinderMenuAction.requestURL(action: .newFile, context: .item, target: folder, selection: [], scheme: FinderActionRequest.scheme) == nil)
        precondition(FinderMenuAction.requestURL(action: .newFile, context: .item, target: folder, selection: [file, file], scheme: FinderActionRequest.scheme) == nil)
        precondition(FinderMenuAction.requestURL(action: .newFile, context: .container, target: nil, selection: [file], scheme: FinderActionRequest.scheme) == nil)
        let containerWithSelection = FinderMenuAction.requestURL(action: .newFile, context: .container, target: folder, selection: [file], scheme: FinderActionRequest.scheme)
        precondition(containerWithSelection.flatMap(FinderActionRequest.parse)?.selection == [])
        let fm = FileManager.default
        let realFolder = fm.temporaryDirectory.appendingPathComponent("Copy path Ж spaces \(UUID())", isDirectory: true)
        try fm.createDirectory(at: realFolder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: realFolder) }
        let realFile = realFolder.appendingPathComponent("file.txt")
        precondition(fm.createFile(atPath: realFile.path, contents: Data()))
        var copied: String?
        func write(_ path: String) -> Bool { copied = path; return true }
        precondition(FinderMenuAction.copyFolderPath(context: .container, target: realFolder, selection: [realFile], write: write))
        precondition(copied == realFolder.path)
        copied = nil
        precondition(FinderMenuAction.copyFolderPath(context: .item, target: nil, selection: [realFolder], write: write))
        precondition(copied == realFolder.path)
        copied = nil
        precondition(FinderMenuAction.copyFolderPath(context: .item, target: nil, selection: [realFile], write: write))
        precondition(copied == realFolder.path)
        copied = nil
        precondition(!FinderMenuAction.copyFolderPath(context: .item, target: realFolder, selection: [], write: write))
        precondition(!FinderMenuAction.copyFolderPath(context: .item, target: realFolder, selection: [realFile, realFile], write: write))
        precondition(!FinderMenuAction.copyFolderPath(context: .container, target: nil, selection: [], write: write))
        precondition(!FinderMenuAction.copyFolderPath(context: .container, target: URL(string: "https://example.com")!, selection: [], write: write))
        precondition(!FinderMenuAction.copyFolderPath(context: .container, target: realFolder.appendingPathComponent("missing"), selection: [], write: write))
        precondition(copied == nil, "Invalid targets must not overwrite the clipboard")
        precondition(!FinderMenuAction.copyFolderPath(context: .container, target: realFolder, selection: [], write: { _ in false }))
        print("PASS: Finder menu callbacks encode all actions and contexts")
        print("PASS: folder paths copied for Finder background, folders and files")
    }
}
