import Foundation

@main
struct FinderMenuActionTests {
    static func main() {
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
        print("PASS: Finder menu callbacks encode all actions and contexts")
    }
}
