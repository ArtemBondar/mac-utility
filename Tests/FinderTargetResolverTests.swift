import Foundation

@main
struct FinderTargetResolverTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("finder-target-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let folder = root.appendingPathComponent("A Folder", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: false)
        let file = root.appendingPathComponent("a file.txt")
        try Data().write(to: file)
        let normalizedRoot = FinderTargetResolver.canonicalFileURL(root)!
        let normalizedFolder = FinderTargetResolver.canonicalFileURL(folder)!
        func expect(_ actual: URL?, _ expected: URL?, _ name: String) {
            precondition(actual == expected, "\(name): got \(String(describing: actual)), expected \(String(describing: expected))")
        }
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [file]), normalizedRoot, "file")
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [folder]), normalizedFolder, "folder")
        expect(FinderTargetResolver.resolve(context: .container, target: root, selection: [folder]), normalizedRoot, "background ignores selection")
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [file, folder]), nil, "multiple")
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: []), nil, "no selection")
        expect(FinderTargetResolver.resolve(context: .container, target: nil, selection: [folder]), nil, "no target")
        expect(FinderTargetResolver.resolve(context: .container, target: file, selection: []), nil, "non-directory background")
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [root.appendingPathComponent("missing")]), nil, "missing")
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [URL(string: "https://example.com")!]), nil, "remote URL")
        let link = root.appendingPathComponent("link")
        try fm.createSymbolicLink(at: link, withDestinationURL: folder)
        expect(FinderTargetResolver.resolve(context: .item, target: root, selection: [link]), normalizedFolder, "symlink resolves")
        print("PASS: Finder target resolution")
    }
}
