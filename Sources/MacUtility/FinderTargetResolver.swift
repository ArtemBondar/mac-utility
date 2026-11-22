import Foundation

/// Resolves the directory for a Finder action. The caller must obtain and maintain
/// security-scoped access and revalidate the destination when performing an operation.
enum FinderTargetResolver {
    enum Context {
        case item
        case container
    }

    /// Multiple selections and missing, remote, non-file or inaccessible locations
    /// are rejected. Finder's background selection is intentionally ignored.
    static func resolve(context: Context, target: URL?, selection: [URL]) -> URL? {
        let candidate: URL
        switch context {
        case .container:
            guard let target else { return nil }
            candidate = target
        case .item:
            guard selection.count == 1 else { return nil }
            candidate = selection[0]
        }
        guard candidate.isFileURL else { return nil }
        let resolved = candidate.standardizedFileURL.resolvingSymlinksInPath()
        guard let values = try? resolved.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .volumeIsLocalKey]),
              values.volumeIsLocal == true else { return nil }
        let destination: URL
        if values.isDirectory == true {
            destination = resolved
        } else if context == .item, values.isRegularFile == true {
            destination = resolved.deletingLastPathComponent()
        } else {
            return nil
        }
        return destination
    }
}
