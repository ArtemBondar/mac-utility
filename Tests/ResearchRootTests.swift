import Foundation

@main
struct ResearchRootTests {
    static func main() {
        precondition(ResearchRoot.url(homePath: "/Users/Test User")?.path == "/Users/Test User/MacUtilityPrototype")
        precondition(ResearchRoot.url(homePath: "/Users/Test/")?.path == "/Users/Test/MacUtilityPrototype")
        precondition(ResearchRoot.url(homePath: "relative") == nil)
        precondition(ResearchRoot.url(homePath: "") == nil)
        precondition(ContextSummary.lines(target: nil, selection: []) == ["Target: (none)", "Selection: (none)"])
        let item = URL(fileURLWithPath: "/tmp/a space.txt")
        precondition(ContextSummary.lines(target: item, selection: [item]) == ["Target: /tmp/a space.txt", "Selection: /tmp/a space.txt"])
        guard let actual = ResearchRoot.currentUserURL(), let home = ProcessInfo.processInfo.environment["HOME"] else {
            fatalError("Could not determine the test account's home")
        }
        let expected = URL(fileURLWithPath: home, isDirectory: true).appendingPathComponent("MacUtilityPrototype").standardizedFileURL
        precondition(actual.path == expected.path, "Account home differs from the test session home")
        print("PASS: prototype root resolves to the account home and rejects relative paths")
    }
}
