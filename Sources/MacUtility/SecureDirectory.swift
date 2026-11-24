import Foundation
import Darwin

/// Keeps the opened destination anchored while the name prompt is displayed.
/// The caller must hold the security scope for `root` for this object's lifetime.
final class SecureDirectory {
    let descriptor: Int32
    private init(_ descriptor: Int32) { self.descriptor = descriptor }
    deinit { close(descriptor) }

    static func open(root: URL, destination: URL) -> SecureDirectory? {
        guard root.isFileURL, destination.isFileURL else { return nil }
        // `standardizedFileURL` can turn /private/var back into /var, a
        // symlink that O_NOFOLLOW correctly rejects. Callers pass physical
        // paths; reject traversal explicitly instead of rewriting them.
        let rootComponents = root.pathComponents
        let targetComponents = destination.pathComponents
        guard !rootComponents.contains("."), !rootComponents.contains(".."),
              !targetComponents.contains("."), !targetComponents.contains(".."),
              targetComponents.count >= rootComponents.count,
              Array(targetComponents.prefix(rootComponents.count)) == rootComponents else { return nil }
        var fd = Darwin.open(root.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
        guard fd >= 0 else { return nil }
        for component in targetComponents.dropFirst(rootComponents.count) {
            let next = openat(fd, component, O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW)
            close(fd)
            guard next >= 0 else { return nil }
            fd = next
        }
        return SecureDirectory(fd)
    }
}
