import Foundation

enum FinderMenuAction {
    enum Action: CaseIterable { case newFile, newFolder, openTerminal }
    enum Context { case item, container }

    static func requestURL(action: Action, context: Context, target: URL?, selection: [URL], scheme: String) -> URL? {
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
