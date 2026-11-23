import SwiftUI
import AppKit
import ServiceManagement

@main
struct MacUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppDelegate.sharedStore
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra(L10n.text("Mac Utility"), systemImage: "folder.badge.gearshape") {
            Text(L10n.text("Finder integration requires setup"))
                .disabled(true)
            Divider()
            Button(L10n.text("Settings…")) {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button(L10n.text("About Mac Utility")) { NSApp.orderFrontStandardAboutPanel(nil) }
            Button(L10n.text("Quit Mac Utility")) { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        Window(L10n.text("Mac Utility Settings"), id: "settings") {
            SettingsView(store: store)
        }
        .defaultSize(width: 520, height: 480)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let sharedStore = SettingsStore(sharedDefaults: UserDefaults(suiteName: FinderConfiguration.groupIdentifier))

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(Self.sharedStore.showDockIcon ? .regular : .accessory)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == FinderActionRequest.scheme {
            FinderRequestHandler.handle(url, store: Self.sharedStore)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.openWindow) private var openWindow
    @State private var message: String?
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section(L10n.text("Finder Integration")) {
                #if DIRECT_DISTRIBUTION
                Text(L10n.text("Enable the Mac Utility Finder extension in System Settings. Actions are available in local folders your account can access."))
                    .foregroundStyle(.secondary)
                #else
                Text(L10n.text("Enable the Mac Utility Finder extension in System Settings and add folders below."))
                    .foregroundStyle(.secondary)
                Text(L10n.text("Choose local folders the app may access. You can remove access at any time."))
                ForEach(store.settings.folders) { folder in
                    HStack {
                        Text(folder.path).textSelection(.enabled)
                        Spacer()
                        Button(L10n.text("Check Access")) {
                            message = store.checkFolder(folder) ? L10n.text("Folder access is available.") : L10n.text("Folder access could not be restored. Remove and add the folder again.")
                        }
                        .accessibilityLabel(L10n.format("Check access for %@", folder.path))
                        Button(L10n.text("Remove")) { store.removeFolder(id: folder.id) }
                            .accessibilityLabel(L10n.format("Remove access for %@", folder.path))
                    }
                }
                Button(L10n.text("Add Folder…")) { chooseFolder() }
                #endif
            }
            Section(L10n.text("Finder Actions")) {
                Toggle(L10n.text("New File"), isOn: actionBinding(\.newFile))
                Toggle(L10n.text("New Folder"), isOn: actionBinding(\.newFolder))
                Toggle(L10n.text("Open Terminal Here"), isOn: actionBinding(\.openTerminal))
            }
            Section(L10n.text("General")) {
                Toggle(L10n.text("Show Dock icon"), isOn: Binding(get: { store.showDockIcon }, set: { visible in
                    store.setShowDockIcon(visible)
                    let openSettings = openWindow
                    DockVisibility.change(visible, setPolicy: { show in
                        NSApp.setActivationPolicy(show ? .regular : .accessory)
                    }, reopenSettings: {
                        openSettings(id: "settings")
                        NSApp.activate(ignoringOtherApps: true)
                    })
                }))
                Toggle(L10n.text("Open at Login"), isOn: Binding(get: { loginEnabled }, set: { setLogin($0) }))
                Text(L10n.text("macOS may require approval in Login Items settings.")).foregroundStyle(.secondary)
            }
            if let message { Text(message).foregroundStyle(.secondary) }
        }
        .formStyle(.grouped)
        .onAppear { loginEnabled = SMAppService.mainApp.status == .enabled }
    }

    private func actionBinding(_ keyPath: WritableKeyPath<StoredSettings, Bool>) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: keyPath] }, set: { value in
            var settings = store.settings
            settings[keyPath: keyPath] = value
            store.setActions(newFile: settings.newFile, newFolder: settings.newFolder, openTerminal: settings.openTerminal)
        })
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.text("Allow Access")
        panel.message = L10n.text("Choose a local folder for future Finder actions.")
        if panel.runModal() == .OK, let url = panel.url {
            defer { url.stopAccessingSecurityScopedResource() }
            do { try store.addFolder(url); message = nil }
            catch { message = L10n.format("Could not save folder access: %@", error.localizedDescription) }
        }
    }

    private func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            message = loginEnabled == enabled ? nil : L10n.text("Open Login Items in System Settings to review approval.")
        } catch {
            loginEnabled = SMAppService.mainApp.status == .enabled
            message = L10n.format("Could not change Open at Login: %@", error.localizedDescription)
        }
    }
}
