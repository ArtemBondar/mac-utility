import Foundation

@main
struct TerminalLauncherTests {
    static func main() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("terminal-test-\(UUID().uuidString)")
        let folder = root.appendingPathComponent("space 'quote' $() ; ü", isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let terminal = URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
        var called = false
        TerminalLauncher.open(folder, terminalURL: { terminal }, launch: { received, app, done in
            precondition(received == folder && app == terminal)
            called = true
            done(nil)
        }, completion: { result in
            guard case .success = result else { fatalError("Expected success") }
        })
        precondition(called)

        for url in [URL(string: "https://example.com")!, root.appendingPathComponent("missing")] {
            TerminalLauncher.open(url, terminalURL: { terminal }, launch: { _, _, _ in fatalError("Invalid folder was launched") }, completion: { result in
                guard case .failure(.invalidFolder) = result else { fatalError("Expected invalid folder") }
            })
        }
        TerminalLauncher.open(folder, terminalURL: { nil }, launch: { _, _, _ in fatalError("Terminal unavailable") }, completion: { result in
            guard case .failure(.terminalUnavailable) = result else { fatalError("Expected missing Terminal") }
        })
        TerminalLauncher.open(folder, terminalURL: { terminal }, launch: { _, _, done in
            done(NSError(domain: "test", code: 1))
        }, completion: { result in
            guard case .failure(.launchFailed) = result else { fatalError("Expected launch failure") }
        })
        print("PASS: Terminal URL handoff, special characters and errors")
    }
}
