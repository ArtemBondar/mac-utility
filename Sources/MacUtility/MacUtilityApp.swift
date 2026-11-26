import SwiftUI
import AppKit
import ServiceManagement
import FinderSync
import OSLog

@main
struct MacUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppDelegate.sharedStore

    var body: some Scene {
        MenuBarExtra(L10n.text("Clicklet"), systemImage: "folder.badge.gearshape") {
            if FIFinderSyncController.isExtensionEnabled {
                Text(L10n.text("Finder extension is enabled."))
                    .disabled(true)
            } else {
                Text(L10n.text("Finder extension is disabled."))
                    .disabled(true)
            }
            Divider()
            Button(L10n.text("Settings…")) {
                AppDelegate.showSettings()
            }
            Button(L10n.text("About Clicklet")) { NSApp.orderFrontStandardAboutPanel(nil) }
            Button(L10n.text("Quit Clicklet")) { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "com.example.MacUtility", category: "FinderAction")
    static let sharedStore = SettingsStore(sharedDefaults: UserDefaults(suiteName: FinderConfiguration.groupIdentifier))
    private static let settingsWindow = SettingsWindowOwner<NSWindowController>()

    static func showSettings() {
        let controller = settingsWindow.getOrCreate {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
            window.title = L10n.text("Clicklet Settings")
            window.contentView = NSHostingView(rootView: SettingsView(store: sharedStore))
            window.isReleasedWhenClosed = false
            window.center()
            return NSWindowController(window: window)
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(Self.sharedStore.showDockIcon ? .regular : .accessory)
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            guard SettingsStore.shouldOfferFinderSetup(
                extensionEnabled: FIFinderSyncController.isExtensionEnabled,
                alreadyOffered: defaults.bool(forKey: "finderSetupOffered.v1")
            ) else { return }
            defaults.set(true, forKey: "finderSetupOffered.v1")
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = L10n.text("Enable Finder extension")
            alert.informativeText = L10n.text("Enable Clicklet in Finder Extensions to show its actions in Finder. You can change this later in Settings.")
            alert.addButton(withTitle: L10n.text("Open Finder Extension Settings"))
            alert.addButton(withTitle: L10n.text("Not Now"))
            if alert.runModal() == .alertFirstButtonReturn {
                FIFinderSyncController.showExtensionManagementInterface()
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == FinderActionRequest.scheme {
            logger.notice("Clicklet received a Finder action")
            FinderRequestHandler.handle(url, store: Self.sharedStore)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var message: String?
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var finderEnabled = FIFinderSyncController.isExtensionEnabled

    var body: some View {
        Form {
            Section(L10n.text("Finder Integration")) {
                if finderEnabled {
                    Text(L10n.text("Finder extension is enabled."))
                } else {
                    Text(L10n.text("Finder extension is disabled."))
                        .foregroundStyle(.secondary)
                }
                Button(L10n.text("Open Finder Extension Settings")) {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
                #if DIRECT_DISTRIBUTION
                Text(L10n.text("Enable the Clicklet Finder extension in System Settings. Actions are available in local folders your account can access."))
                    .foregroundStyle(.secondary)
                #else
                Text(L10n.text("Enable the Clicklet Finder extension in System Settings and add folders below."))
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
                Toggle(L10n.text("Copy Folder Path"), isOn: actionBinding(\.copyFolderPath))
            }
            Section(L10n.text("General")) {
                Toggle(L10n.text("Show Dock icon"), isOn: Binding(get: { store.showDockIcon }, set: { visible in
                    store.setShowDockIcon(visible)
                    DockVisibility.change(visible, setPolicy: { show in
                        NSApp.setActivationPolicy(show ? .regular : .accessory)
                    }, reopenSettings: {
                        AppDelegate.showSettings()
                    })
                }))
                Toggle(L10n.text("Open at Login"), isOn: Binding(get: { loginEnabled }, set: { setLogin($0) }))
                Text(L10n.text("macOS may require approval in Login Items settings.")).foregroundStyle(.secondary)
            }
            if let message { Text(message).foregroundStyle(.secondary) }
        }
        .formStyle(.grouped)
        .onAppear {
            loginEnabled = SMAppService.mainApp.status == .enabled
            finderEnabled = FIFinderSyncController.isExtensionEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            finderEnabled = FIFinderSyncController.isExtensionEnabled
        }
    }

    private func actionBinding(_ keyPath: WritableKeyPath<StoredSettings, Bool>) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: keyPath] }, set: { value in
            var settings = store.settings
            settings[keyPath: keyPath] = value
            store.setActions(newFile: settings.newFile, newFolder: settings.newFolder, openTerminal: settings.openTerminal, copyFolderPath: settings.copyFolderPath)
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
