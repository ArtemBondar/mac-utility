import Foundation

@main
struct SecureDirectoryTests {
    static func main() throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("macutility-secure-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: base) }
        let root = base.appendingPathComponent("root")
        let child = root.appendingPathComponent("child")
        let outside = base.appendingPathComponent("root-other")
        try fm.createDirectory(at: child, withIntermediateDirectories: true)
        try fm.createDirectory(at: outside, withIntermediateDirectories: true)
        let canonicalRoot = root.resolvingSymlinksInPath()
        let canonicalChild = child.resolvingSymlinksInPath()
        guard let fd = SecureDirectory.open(root: canonicalRoot, destination: canonicalChild) else { fatalError("directory should open") }
        precondition(SecureDirectory.open(root: canonicalRoot, destination: outside.resolvingSymlinksInPath()) == nil)
        let traversal = URL(fileURLWithPath: canonicalRoot.path + "/../root-other", isDirectory: true)
        precondition(SecureDirectory.open(root: canonicalRoot, destination: traversal) == nil, "path traversal must not escape the granted root")
        let moved = root.appendingPathComponent("moved")
        try fm.moveItem(at: child, to: moved)
        try fm.createSymbolicLink(at: child, withDestinationURL: outside)
        precondition(SecureDirectory.open(root: canonicalRoot, destination: canonicalChild) == nil)
        _ = try FileCreation.create(.file, name: "safe.txt", in: canonicalChild, directoryFD: fd.descriptor)
        precondition(fm.fileExists(atPath: moved.appendingPathComponent("safe.txt").path))
        precondition(!fm.fileExists(atPath: outside.appendingPathComponent("safe.txt").path))
        print("PASS: folder containment and descriptor-anchored creation")
    }
}
