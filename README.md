# Mac Utility

A lightweight macOS menu bar utility in early development. The intended Finder actions are New File, New Folder, and Open Terminal Here.

## Current state

An initial Finder Sync extension and host action handoff are included. This integration is experimental and has not been tested end-to-end with a provisioned App Group, real folder grants, or a signed distribution build. Initial product scope is local files on current macOS. `FinderSyncPrototype/` remains an unrelated research stub.

## Build and run

Open `MacUtility.xcodeproj` in Xcode, select the MacUtility scheme and My Mac, and run. The app has no Dock icon; use its menu bar icon to quit. To sign with your Apple account, choose your development team under **Signing & Capabilities** and replace the placeholder `com.example.MacUtility` bundle identifier with a unique identifier you control. The project enables App Sandbox, hardened runtime, and automatic signing; no team or credentials are stored in the project.

The Finder extension and containing app share the placeholder App Group `group.com.example.MacUtility`. Configure a unique App Group for your team, replacing the identifier in `FinderConfiguration.swift`, `MacUtility.entitlements`, and `FinderExtension.entitlements`; configure unique bundle identifiers and signing for both targets. App Group provisioning is required for a normal signed build. No working team configuration or distribution signature has yet been verified. `bash Tests/verify-app-bundle.sh` performs unsigned compilation and manual ad-hoc signing for bundle checks only; it does not prove App Group access.

The menu bar Settings window lets you select folders, check or remove saved access, choose future actions, and request launch at login. macOS may require login-item approval. Folder access uses app-scoped bookmarks in the containing app. Only paths and action preferences are shared with the extension; bookmarks stay in the containing app. Finder integration enablement, cross-process configuration, folder selection and restored access in a signed app, and login-item behavior remain unverified. Initial product scope is local files on current macOS.

## Automated verification

Run `bash Tests/verify-app-bundle.sh` on a Mac with Xcode installed. It builds a fresh ad-hoc signed app and verifies the executable, bundle type, minimum version, accessory configuration, signature, sandbox, and hardened runtime. The check does not verify that the menu appears or that Quit works, nor does it test a Developer ID signature or execution on macOS 13. Those require interactive testing and appropriate signing credentials.

Run `bash Tests/verify-finder-configuration.sh`, `bash Tests/verify-finder-requests.sh` to check shared configuration, untrusted request parsing, containment and descriptor-anchored creation. The URL scheme is not sender-authenticated: the host validates user-granted scope and preferences, and requires confirmation before each operation. Do not treat these tests as proof of live App Group or Finder behavior.

Run `bash Tests/verify-settings.sh` for isolated settings persistence, folder removal and invalid-bookmark handling. This does not replace interactive permission, login-item, and Finder extension testing.

Run `bash Tests/verify-finder-target.sh` for local file, folder, background and ambiguous-selection resolution. The host resolves requests from the extension using this resolver. It rejects multiple selected items, missing paths and nonlocal volumes; resolves symbolic links; and requires its caller to verify folder authorization and revalidate access when performing an operation. Actual Finder integration, security-scoped access and behavior on cloud-backed volumes remain unverified.

Run `bash Tests/verify-file-creation.sh` to verify empty file and folder creation, validation, existing-item protection and concurrent name collisions. The creation service and native prompt are wired to the host request handler; interactive prompting, sandbox folder authorization and end-to-end Finder actions remain unverified. The caller must hold security-scoped access to the target folder during creation.

Run `bash Tests/verify-terminal-launcher.sh` for URL handoff, special characters, invalid targets, missing Terminal, and launch failures. The launcher uses Launch Services to pass the directory URL to Terminal without interpolating shell commands or requesting Automation permission. A standalone unsandboxed probe returned successful handoff on this Mac; Terminal's working directory could not be inspected in this environment. A successful handoff does not establish the working directory. Sandboxed behavior, permission failures, and Finder integration remain unverified; the caller must hold folder access and report the localized error on failure.

The menu bar shell can also be built as a Swift package with Xcode command-line tools:

```sh
swift run MacUtility
```

A distributable signed release is not implemented.

See [release preparation](docs/RELEASE.md) for a read-only preflight and the outstanding signing, notarization, and clean-account checks.

See [verification results](docs/VERIFICATION.md) for accessibility and robustness checks, an initial idle resource sample, and remaining manual work.

## Finder integration constraint

Apple documents Finder Sync for file synchronization apps and says it is not intended as a general tool for modifying Finder. Its contextual menu applies to monitored directories. Investigate Finder Sync and Services with a signed, sandboxed prototype, including background clicks, selected folders, permissions and distribution viability before choosing a solution. The placeholder prototype must not be represented as a supported integration.

See [the development plan](docs/DEVELOPMENT_PLAN.md) and [Apple's Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).

The [Finder integration research](docs/FINDER_INTEGRATION_RESEARCH.md) describes the diagnostic prototypes, automated packaging checks, and remaining manual feasibility work.

## Localization

The app follows the system language and includes English and Ukrainian; English is the development-language fallback. User-visible text is looked up through `L10n` and `Localizable.strings` resources. To add a language, create a new language `.lproj` directory in `Sources/MacUtility/Resources`, translate every key, and add it to the Xcode `Localizable.strings` variant group and known regions. Keep format placeholders compatible. Run `bash Tests/verify-localization.sh` and `bash Tests/verify-app-bundle.sh` after changing translations. Plural-sensitive text should use native `.stringsdict` resources when introduced.

Actual English and Ukrainian UI rendering, text truncation, VoiceOver, and language fallback should also be verified interactively; they have not yet been tested. The research-only Finder prototype is not localized.
