import AppKit
import Carbon

/// SwiftUI can consume URL events before forwarding them to a delegate, and a
/// closed MenuBarExtra has no live view for onOpenURL.
final class FinderURLReceiver: NSObject {
    private let receive: (URL) -> Void

    init(receive: @escaping (URL) -> Void) {
        self.receive = receive
    }

    func install() {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let value = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: value), url.scheme == FinderActionRequest.scheme else { return }
        receive(url)
    }
}
