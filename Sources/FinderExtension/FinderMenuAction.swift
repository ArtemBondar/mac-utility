import Foundation

enum FinderMenuAction {
    enum Action: CaseIterable { case newFile, newFolder, openTerminal }
    enum Context { case item, container }

    /// Copy directly from the Finder extension: no unauthenticated host URL can
    /// trigger clipboard changes. The path stays in the form Finder displayed.
    @discardableResult
    static func copyFolderPath(context: Context, target: URL?, selection: [URL],
                               write: (String) -> Bool) -> Bool {
        let candidate: URL
        switch context {
        case .container:
            guard let target else { return false }
            candidate = target
        case .item:
            guard selection.count == 1 else { return false }
            candidate = selection[0]
        }
        guard candidate.isFileURL, candidate.host == nil || candidate.host == "" || candidate.host == "localhost" else { return false }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory) else { return false }
        let folder = isDirectory.boolValue ? candidate : candidate.deletingLastPathComponent()
        guard folder.path.hasPrefix("/") else { return false }
        return write(folder.path)
    }

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
