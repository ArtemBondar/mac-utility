import SwiftUI
import AppKit
import ServiceManagement

@main
struct MacUtilityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = SettingsStore()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("Mac Utility", systemImage: "folder.badge.gearshape") {
            Text("Finder integration: not installed")
                .disabled(true)
            Divider()
            Button("Settings…") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("About Mac Utility") { NSApp.orderFrontStandardAboutPanel(nil) }
            Button("Quit Mac Utility") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        Window("Mac Utility Settings", id: "settings") {
            SettingsView(store: store)
        }
        .defaultSize(width: 520, height: 480)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var message: String?
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("Finder Integration") {
                Text("The Finder extension is not installed yet. These preferences will take effect when integration is available.")
                    .foregroundStyle(.secondary)
                Text("Choose local folders the app may access. You can remove access at any time.")
                ForEach(store.settings.folders) { folder in
                    HStack {
                        Text(folder.path).textSelection(.enabled)
                        Spacer()
                        Button("Check Access") {
                            message = store.checkFolder(folder) ? "Folder access is available." : "Folder access could not be restored. Remove and add the folder again."
                        }
                        Button("Remove") { store.removeFolder(id: folder.id) }
                    }
                }
                Button("Add Folder…") { chooseFolder() }
            }
            Section("Finder Actions") {
                Toggle("New File", isOn: actionBinding(\.newFile))
                Toggle("New Folder", isOn: actionBinding(\.newFolder))
                Toggle("Open Terminal Here", isOn: actionBinding(\.openTerminal))
            }
            Section("General") {
                Toggle("Open at Login", isOn: Binding(get: { loginEnabled }, set: { setLogin($0) }))
                Text("macOS may require approval in Login Items settings.").foregroundStyle(.secondary)
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
        panel.prompt = "Allow Access"
        panel.message = "Choose a local folder for future Finder actions."
        if panel.runModal() == .OK, let url = panel.url {
            defer { url.stopAccessingSecurityScopedResource() }
            do { try store.addFolder(url); message = nil }
            catch { message = "Could not save folder access: \(error.localizedDescription)" }
        }
    }

    private func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            loginEnabled = SMAppService.mainApp.status == .enabled
            message = loginEnabled == enabled ? nil : "Open Login Items in System Settings to review approval."
        } catch {
            loginEnabled = SMAppService.mainApp.status == .enabled
            message = "Could not change Open at Login: \(error.localizedDescription)"
        }
    }
}
