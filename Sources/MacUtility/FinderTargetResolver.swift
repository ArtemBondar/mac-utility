import Foundation
import Darwin

/// Resolves the directory for a Finder action. The caller must obtain and maintain
/// security-scoped access and revalidate the destination when performing an operation.
enum FinderTargetResolver {
    /// Resolve every path component to the physical path used by openat. On
    /// macOS Foundation may preserve aliases such as /var, which is a symlink.
    static func canonicalFileURL(_ url: URL) -> URL? {
        guard url.isFileURL, let resolved = realpath(url.path, nil) else { return nil }
        defer { free(resolved) }
        let path = String(cString: resolved)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }
        return URL(fileURLWithPath: path, isDirectory: isDirectory.boolValue)
    }
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
        guard let resolved = canonicalFileURL(candidate) else { return nil }
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
