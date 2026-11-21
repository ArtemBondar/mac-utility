import Foundation
import Darwin

// A fixed, disposable test folder. Real product code must obtain user authorization.
enum ResearchRoot {
    static func url(homePath: String) -> URL? {
        guard homePath.hasPrefix("/"), !homePath.isEmpty else { return nil }
        return URL(fileURLWithPath: homePath, isDirectory: true)
            .appendingPathComponent("MacUtilityPrototype", isDirectory: true)
            .standardizedFileURL
    }

    static func currentUserURL() -> URL? {
        guard let entry = getpwuid(getuid()), let path = entry.pointee.pw_dir else { return nil }
        return url(homePath: String(cString: path))
    }
}
