import Foundation

@main
struct FinderMenuActionTests {
    static func main() {
        let folder = URL(fileURLWithPath: "/tmp/A & Ж", isDirectory: true)
        let file = folder.appendingPathComponent("a #.txt")
        for action in FinderMenuAction.Action.allCases {
            for context in [FinderMenuAction.Context.item, .container] {
                // Model Finder copying only the menu item's supported tag.
                let copiedTag = FinderMenuAction.tag(action: action, context: context)
                guard let url = FinderMenuAction.requestURL(tag: copiedTag, target: folder,
                    selection: context == .item ? [file] : [], scheme: FinderActionRequest.scheme),
                      let request = FinderActionRequest.parse(url) else { fatalError("Missing request") }
                let expected: FinderActionRequest.Action = action == .newFile ? .newFile : action == .newFolder ? .newFolder : .openTerminal
                precondition(request.action == expected && request.target == folder)
                precondition(request.context == (context == .item ? .item : .container))
                precondition(request.selection == (context == .item ? [file] : []))
            }
        }
        precondition(FinderMenuAction.requestURL(tag: 0, target: folder, selection: [], scheme: FinderActionRequest.scheme) == nil)
        precondition(FinderMenuAction.requestURL(tag: 11, target: folder, selection: [], scheme: FinderActionRequest.scheme) == nil)
        precondition(FinderMenuAction.requestURL(tag: 21, target: nil, selection: [], scheme: FinderActionRequest.scheme) == nil)
        print("PASS: copied Finder menu tags dispatch all actions and contexts")
    }
}
