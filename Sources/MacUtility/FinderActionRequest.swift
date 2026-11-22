import Foundation

/// Treat URL-scheme input as untrusted; callers must still check folder grants.
struct FinderActionRequest {
    enum Action: String { case newFile, newFolder, openTerminal }
    enum Context: String { case item, container }
    let action: Action
    let context: Context
    let target: URL?
    let selection: [URL]

    static func parse(_ url: URL) -> FinderActionRequest? {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "macutility-finder", parts.host == "action",
              parts.path.isEmpty, parts.user == nil, parts.password == nil,
              parts.port == nil, parts.fragment == nil else { return nil }
        let items = parts.queryItems ?? []
        guard items.count <= 4,
              items.allSatisfy({ ["action", "context", "target", "selection"].contains($0.name) && $0.value != nil }) else { return nil }
        func one(_ key: String) -> String? {
            let matches = items.filter { $0.name == key }
            guard matches.count == 1 else { return nil }
            return matches[0].value
        }
        guard let actionString = one("action"), let action = Action(rawValue: actionString),
              let contextString = one("context"), let context = Context(rawValue: contextString) else { return nil }
        func fileURL(_ value: String) -> URL? {
            guard let url = URL(string: value), url.isFileURL,
                  url.host == nil || url.host == "" || url.host == "localhost",
                  url.path.hasPrefix("/"), url.query == nil, url.fragment == nil else { return nil }
            return url
        }
        let targets = items.filter { $0.name == "target" }
        guard targets.count <= 1 else { return nil }
        let target = targets.first?.value.flatMap(fileURL)
        if !targets.isEmpty && target == nil { return nil }
        let selections = items.filter { $0.name == "selection" }
        guard selections.count <= 1 else { return nil }
        let selection = selections.compactMap { $0.value.flatMap(fileURL) }
        guard selection.count == selections.count else { return nil }
        guard (context == .item && selection.count == 1) || (context == .container && target != nil) else { return nil }
        return FinderActionRequest(action: action, context: context, target: target, selection: selection)
    }
}
