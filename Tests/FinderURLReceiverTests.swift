import AppKit
import Carbon

@main
struct FinderURLReceiverTests {
    static func main() {
        var received: [URL] = []
        let receiver = FinderURLReceiver { received.append($0) }
        let event = NSAppleEventDescriptor.appleEvent(withEventClass: AEEventClass(kInternetEventClass),
                                                       eventID: AEEventID(kAEGetURL),
                                                       targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID),
                                                       transactionID: AETransactionID(kAnyTransactionID))
        let reply = NSAppleEventDescriptor.null()
        receiver.handleGetURL(event, withReplyEvent: reply)
        precondition(received.isEmpty)
        event.setParam(NSAppleEventDescriptor(string: "https://example.com"), forKeyword: AEKeyword(keyDirectObject))
        receiver.handleGetURL(event, withReplyEvent: reply)
        precondition(received.isEmpty)
        let request = "\(FinderActionRequest.scheme)://action?action=newFolder&context=container&target=file:///tmp"
        event.setParam(NSAppleEventDescriptor(string: request), forKeyword: AEKeyword(keyDirectObject))
        receiver.handleGetURL(event, withReplyEvent: reply)
        precondition(received.count == 1 && FinderActionRequest.parse(received[0])?.action == .newFolder)
        print("PASS: persistent URL event receiver filters and forwards Finder requests")
    }
}
