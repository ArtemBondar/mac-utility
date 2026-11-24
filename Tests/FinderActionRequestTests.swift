import Foundation

@main
struct FinderActionRequestTests {
    static func main() {
        func make(_ items: [URLQueryItem]) -> URL {
            var components = URLComponents()
            components.scheme = FinderActionRequest.scheme
            components.host = "action"
            components.queryItems = items
            return components.url!
        }
        let special = URL(fileURLWithPath: "/tmp/A ' & Ж.txt")
        let valid = [URLQueryItem(name: "action", value: "newFile"),
                     URLQueryItem(name: "context", value: "item"),
                     URLQueryItem(name: "selection", value: special.absoluteString)]
        precondition(FinderActionRequest.parse(make(valid))?.selection == [special])
        precondition(FinderActionRequest.parse(make(valid + [URLQueryItem(name: "action", value: "openTerminal")])) == nil)
        precondition(FinderActionRequest.parse(make(valid + [URLQueryItem(name: "selection", value: special.absoluteString)])) == nil)
        precondition(FinderActionRequest.parse(make(valid + [URLQueryItem(name: "unknown", value: "x")])) == nil)
        precondition(FinderActionRequest.parse(make([URLQueryItem(name: "action", value: "newFile"), URLQueryItem(name: "context", value: "item"), URLQueryItem(name: "selection", value: "https://example.com")])) == nil)
        precondition(FinderActionRequest.parse(URL(string: "https://action?action=newFile&context=item")!) == nil)
        #if DIRECT_DISTRIBUTION
        precondition(FinderActionRequest.scheme == "macutility-finder-direct")
        precondition(FinderActionRequest.parse(URL(string: "macutility-finder://action?action=newFile&context=container&target=file:///tmp")!) == nil)
        #else
        precondition(FinderActionRequest.scheme == "macutility-finder")
        precondition(FinderActionRequest.parse(URL(string: "macutility-finder-direct://action?action=newFile&context=container&target=file:///tmp")!) == nil)
        #endif
        let background = [URLQueryItem(name: "action", value: "newFolder"), URLQueryItem(name: "context", value: "container"), URLQueryItem(name: "target", value: URL(fileURLWithPath: "/tmp").absoluteString)]
        precondition(FinderActionRequest.parse(make(background))?.context == .container)
        precondition(FinderActionRequest.parse(make(Array(background.prefix(2)))) == nil)
        print("PASS: untrusted Finder URL request validation")
    }
}
