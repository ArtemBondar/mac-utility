# Mac Utility

A lightweight macOS menu bar utility. Finder actions include New File, New Folder, Open Terminal Here, and Copy Folder Path.

## Current state

Version 1.0.0 uses the Direct configuration for local files on current macOS. Finder actions have been tested in the Direct build, including user confirmation of one-click Terminal and path copying. The GitHub download is ad-hoc signed and not notarized. The sandboxed Debug/Release configurations and provisioned App Group distribution remain unverified. `FinderSyncPrototype/` remains an unrelated research stub.

## Build and run

Local Direct previews receive a numeric build version shared by the host and extension. If Finder still displays an older preview's actions after opening a new app copy, run `python3 scripts/activate_direct_preview.py /absolute/path/to/MacUtility.app`. This verifies the signature, unregisters other Direct preview copies from PlugInKit and Launch Services, stops only those stale Direct app/extension processes, and registers the selected copy. It preserves app files, preferences, the sandboxed distribution, extension enablement, and privacy permissions. Keep the selected app in place while testing.

The experimental `Direct` Xcode configuration is intended for testing broad local Finder coverage without selecting folders individually. Its host runs **without App Sandbox**, while its Finder extension remains sandboxed; it is not suitable for Mac App Store distribution. Normal macOS privacy controls and filesystem permissions still apply. The extension monitors `/` and sends requests to a dedicated URL scheme; the host validates the destination and enabled actions. File and folder creation prompt for a name; Terminal opens without a confirmation. The `Debug` and `Release` sandboxed configurations are unchanged.

On first launch, if the Finder extension is disabled, the app offers to open macOS extension settings. Enable Mac Utility there; the app cannot enable the extension on your behalf. The menu bar and Settings show its status, and Settings can reopen extension management. macOS may separately request access to protected locations.

Copy Folder Path puts the current or selected folder's absolute path on the clipboard without a prompt. When a file is selected, it copies that file's containing folder. This action runs in the Finder extension, not through the app's public URL scheme. The action was confirmed working in user testing; protected-folder behavior remains unverified.

Run `bash Tests/verify-dock-window.sh` in a graphical macOS session to check that an AppKit settings window remains visible through Dock activation-policy changes. This exercises the window lifecycle, not the packaged app's toggle.

Open `MacUtility.xcodeproj` in Xcode, select the MacUtility scheme and My Mac, and run. The Dock icon is hidden by default; use **Show Dock icon** in Settings to show it. The menu bar icon remains available to open Settings or quit. To sign with your Apple account, choose your development team under **Signing & Capabilities** and replace the placeholder `com.example.MacUtility` bundle identifier with a unique identifier you control. The project enables App Sandbox, hardened runtime, and automatic signing; no team or credentials are stored in the project.

The Finder extension and containing app share the placeholder App Group `group.com.example.MacUtility`. Configure a unique App Group for your team, replacing the identifier in `FinderConfiguration.swift`, `MacUtility.entitlements`, and `FinderExtension.entitlements`; configure unique bundle identifiers and signing for both targets. App Group provisioning is required for a normal signed build. No working team configuration or distribution signature has yet been verified. `bash Tests/verify-app-bundle.sh` performs unsigned compilation and manual ad-hoc signing for bundle checks only; it does not prove App Group access.

The menu bar Settings window lets you select folders, check or remove saved access, choose future actions, and request launch at login. macOS may require login-item approval. Folder access uses app-scoped bookmarks in the containing app. Only paths and action preferences are shared with the extension; bookmarks stay in the containing app. Finder integration enablement, cross-process configuration, folder selection and restored access in a signed app, and login-item behavior remain unverified. Initial product scope is local files on current macOS.

## Automated verification

Run `bash Tests/verify-app-bundle.sh` on a Mac with Xcode installed. It builds a fresh ad-hoc signed app and verifies the executable, bundle type, minimum version, accessory configuration, signature, sandbox, and hardened runtime. The check does not verify that the menu appears or that Quit works, nor does it test a Developer ID signature or execution on macOS 13. Those require interactive testing and appropriate signing credentials.

Run `bash Tests/verify-finder-configuration.sh`, `bash Tests/verify-finder-requests.sh` to check shared configuration, untrusted request parsing, containment, descriptor-anchored creation, and the immediate Terminal handoff. The URL scheme is not sender-authenticated: another local app can request that Terminal open in an accessible local directory while the action is enabled. File and folder creation still require entering a name. Do not treat these tests as proof of live App Group or Finder behavior.

The Finder request checks also exercise the direct-build action pipeline, including physical paths behind macOS symbolic links. The ad-hoc signed Direct preview was tested through Finder with selected items and folder backgrounds. See [Finder verification](docs/VERIFICATION.md#finder-actions) for the tested contexts and preview registration notes.

Run `bash Tests/verify-settings.sh` for isolated settings persistence, folder removal and invalid-bookmark handling. This does not replace interactive permission, login-item, and Finder extension testing.

Run `bash Tests/verify-finder-target.sh` for local file, folder, background and ambiguous-selection resolution. The host resolves requests from the extension using this resolver. It rejects multiple selected items, missing paths and nonlocal volumes; resolves symbolic links; and requires its caller to verify folder authorization and revalidate access when performing an operation. Actual Finder integration, security-scoped access and behavior on cloud-backed volumes remain unverified.

Run `bash Tests/verify-file-creation.sh` to verify empty file and folder creation, validation, existing-item protection and concurrent name collisions. The creation service and native prompt are wired to the host request handler; interactive prompting, sandbox folder authorization and end-to-end Finder actions remain unverified. The caller must hold security-scoped access to the target folder during creation.

Run `bash Tests/verify-terminal-launcher.sh` for URL handoff, special characters, invalid targets, missing Terminal, and launch failures. The launcher uses Launch Services to pass the directory URL to Terminal without interpolating shell commands or requesting Automation permission. Live Finder testing in the Direct preview confirmed Terminal's working directory for both a selected folder and the current folder. Live sandboxed behavior and macOS permission failures remain unverified. The caller must hold folder access and report the localized error on failure.

The menu bar shell can also be built as a Swift package with Xcode command-line tools:

```sh
swift run MacUtility
```

The GitHub download is ad-hoc signed. Developer ID signing and notarization are not implemented.

See [release preparation](docs/RELEASE.md) for a read-only preflight and the outstanding signing, notarization, and clean-account checks.

See [verification results](docs/VERIFICATION.md) for accessibility and robustness checks, an initial idle resource sample, and remaining manual work.

## Finder integration constraint

Apple documents Finder Sync for file synchronization apps and says it is not intended as a general tool for modifying Finder. Its contextual menu applies to monitored directories. Investigate Finder Sync and Services with a signed, sandboxed prototype, including background clicks, selected folders, permissions and distribution viability before choosing a solution. The placeholder prototype must not be represented as a supported integration.

See [the development plan](docs/DEVELOPMENT_PLAN.md) and [Apple's Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).

The [Finder integration research](docs/FINDER_INTEGRATION_RESEARCH.md) describes the diagnostic prototypes, automated packaging checks, and remaining manual feasibility work.

## Localization

The app follows the system language and includes English and Ukrainian; English is the development-language fallback. User-visible text is looked up through `L10n` and `Localizable.strings` resources. To add a language, create a new language `.lproj` directory in `Sources/MacUtility/Resources`, translate every key, and add it to the Xcode `Localizable.strings` variant group and known regions. Keep format placeholders compatible. Run `bash Tests/verify-localization.sh` and `bash Tests/verify-app-bundle.sh` after changing translations. Plural-sensitive text should use native `.stringsdict` resources when introduced.

Actual English and Ukrainian UI rendering, text truncation, VoiceOver, and language fallback should also be verified interactively; they have not yet been tested. The research-only Finder prototype is not localized.
