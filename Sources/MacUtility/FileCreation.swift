import Foundation
import Darwin

/// The caller must hold security-scoped access to the destination throughout the operation.
enum FileCreation {
    enum Kind { case file, folder }
    enum Failure: LocalizedError {
        case invalidName
        case invalidDestination
        case system(Int32)

        var errorDescription: String? {
            switch self {
            case .invalidName: return L10n.text("Enter a name without a slash or null character.")
            case .invalidDestination: return L10n.text("The destination folder is unavailable.")
            case .system(let code) where code == EEXIST: return L10n.text("An item with that name already exists.")
            case .system(let code): return NSError(domain: NSPOSIXErrorDomain, code: Int(code)).localizedDescription
            }
        }
    }

    /// Creates exactly one item. Exclusive creation prevents overwriting even under races.
    static func create(_ kind: Kind, name: String, in directory: URL) throws -> URL {
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0") else {
            throw Failure.invalidName
        }
        guard directory.isFileURL else { throw Failure.invalidDestination }
        let fd = open(directory.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard fd >= 0 else { throw Failure.system(errno) }
        defer { close(fd) }
        switch kind {
        case .file:
            let result = openat(fd, name, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, mode_t(0o666))
            guard result >= 0 else { throw Failure.system(errno) }
            close(result)
        case .folder:
            guard mkdirat(fd, name, mode_t(0o777)) == 0 else { throw Failure.system(errno) }
        }
        return directory.appendingPathComponent(name, isDirectory: kind == .folder)
    }
}
