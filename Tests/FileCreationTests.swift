import Foundation
import Darwin

@main
struct FileCreationTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("creation-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: root) }
        let file = try FileCreation.create(.file, name: "hello world.txt", in: root)
        let initialData = try Data(contentsOf: file)
        precondition(initialData.isEmpty)
        let folder = try FileCreation.create(.folder, name: "New Folder", in: root)
        var isDirectory: ObjCBool = false
        precondition(fm.fileExists(atPath: folder.path, isDirectory: &isDirectory) && isDirectory.boolValue)
        try Data("keep".utf8).write(to: file)
        func expectFailure(_ operation: () throws -> Void, matching check: (FileCreation.Failure) -> Bool) {
            do { try operation(); fatalError("Expected failure") }
            catch let failure as FileCreation.Failure { precondition(check(failure)) }
            catch { fatalError("Unexpected error: \(error)") }
        }
        func duplicate(_ failure: FileCreation.Failure) -> Bool {
            if case .system(EEXIST) = failure { return true }; return false
        }
        for kind in [FileCreation.Kind.file, .folder] {
            expectFailure({ _ = try FileCreation.create(kind, name: "hello world.txt", in: root) }, matching: duplicate)
            expectFailure({ _ = try FileCreation.create(kind, name: "New Folder", in: root) }, matching: duplicate)
            for name in ["", ".", "..", "a/b", "a\0b"] {
                expectFailure({ _ = try FileCreation.create(kind, name: name, in: root) }) { if case .invalidName = $0 { return true }; return false }
            }
        }
        let retainedData = try Data(contentsOf: file)
        precondition(retainedData == Data("keep".utf8))
        expectFailure({ _ = try FileCreation.create(.file, name: "test", in: root.appendingPathComponent("missing")) }) { if case .system(ENOENT) = $0 { return true }; return false }
        expectFailure({ _ = try FileCreation.create(.file, name: "test", in: file) }) { if case .system(ENOTDIR) = $0 { return true }; return false }
        expectFailure({ _ = try FileCreation.create(.file, name: "test", in: URL(string: "https://example.com")!) }) { if case .invalidDestination = $0 { return true }; return false }
        let symlink = root.appendingPathComponent("existing-link")
        try fm.createSymbolicLink(at: symlink, withDestinationURL: root.appendingPathComponent("missing"))
        expectFailure({ _ = try FileCreation.create(.file, name: "existing-link", in: root) }, matching: duplicate)
        for kind in [FileCreation.Kind.file, .folder] {
            let lock = NSLock()
            var successes = 0, conflicts = 0
            DispatchQueue.concurrentPerform(iterations: 20) { _ in
                do { _ = try FileCreation.create(kind, name: kind == .file ? "race-file" : "race-folder", in: root); lock.lock(); successes += 1; lock.unlock() }
                catch FileCreation.Failure.system(EEXIST) { lock.lock(); conflicts += 1; lock.unlock() }
                catch { fatalError("Unexpected race error: \(error)") }
            }
            precondition(successes == 1 && conflicts == 19)
        }
        print("PASS: exclusive file and folder creation, validation and concurrent collisions")
    }
}
