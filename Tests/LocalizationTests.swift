import Foundation

@main
struct LocalizationTests {
    static func main() {
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        func bundle(_ language: String) -> Bundle {
            guard let result = Bundle(url: root.appendingPathComponent("\(language).lproj")) else {
                fatalError("Missing language bundle: \(language)")
            }
            return result
        }
        let english = bundle("en")
        let ukrainian = bundle("uk")
        let key = "New Folder"
        precondition(english.localizedString(forKey: key, value: nil, table: nil) == "New Folder")
        precondition(ukrainian.localizedString(forKey: key, value: nil, table: nil) == "Нова папка")
        let pattern = ukrainian.localizedString(forKey: "Could not save folder access: %@", value: nil, table: nil)
        precondition(String(format: pattern, "example").contains("example"))
        print("PASS: language bundle lookup and formatted translation")
    }
}
