import Foundation

/// Finder copies menu items across processes and preserves tags, not arbitrary
/// represented objects. Decode the tag and read the current Finder context at
/// the moment the user selects an action.
enum FinderMenuAction {
    enum Action: Int, CaseIterable { case newFile = 1, newFolder = 2, openTerminal = 3 }
    enum Context: Int { case item = 10, container = 20 }

    static func tag(action: Action, context: Context) -> Int { action.rawValue + context.rawValue }

    static func requestURL(tag: Int, target: URL?, selection: [URL], scheme: String) -> URL? {
        guard let context = Context(rawValue: (tag / 10) * 10),
              let action = Action(rawValue: tag % 10) else { return nil }
        guard context != .item || selection.count == 1 else { return nil }
        guard context != .container || target != nil else { return nil }
        let actionName: String
        switch action {
        case .newFile: actionName = "newFile"
        case .newFolder: actionName = "newFolder"
        case .openTerminal: actionName = "openTerminal"
        }
        var components = URLComponents()
        components.scheme = scheme
        components.host = "action"
        components.queryItems = [URLQueryItem(name: "action", value: actionName),
                                 URLQueryItem(name: "context", value: context == .item ? "item" : "container")]
        if let target { components.queryItems?.append(URLQueryItem(name: "target", value: target.absoluteString)) }
        if context == .item {
            components.queryItems?.append(URLQueryItem(name: "selection", value: selection[0].absoluteString))
        }
        return components.url
    }
}
