# Mac Utility

A lightweight macOS menu bar utility in early development. The intended Finder actions are New File, New Folder, and Open Terminal Here.

## Current state

The SwiftUI menu bar shell targets macOS 13 or later. It does **not** yet install Finder commands or perform file operations. `FinderSyncPrototype/` contains an unbundled research stub; it is not an enabled Finder extension. The first integration milestone is to validate an appropriate integration before committing to the implementation.

## Build and run

Open `MacUtility.xcodeproj` in Xcode, select the MacUtility scheme and My Mac, and run. The app has no Dock icon; use its menu bar icon to quit. To sign with your Apple account, choose your development team under **Signing & Capabilities** and replace the placeholder `com.example.MacUtility` bundle identifier with a unique identifier you control. The project enables App Sandbox, hardened runtime, and automatic signing; no team or credentials are stored in the project.

For a locally ad-hoc-signed build without an Apple signing identity:

```sh
xcodebuild -project MacUtility.xcodeproj -scheme MacUtility -configuration Debug \
  -derivedDataPath /tmp/macutility-build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```

The resulting app is `/tmp/macutility-build/Build/Products/Debug/MacUtility.app`. Ad-hoc signing is for local testing, not a notarized distribution build. For distribution, select the appropriate team, unique identifier, signing certificate and provisioning in Xcode; archive and notarize or submit through the intended channel. Distribution signing has not yet been verified.

The menu bar Settings window lets you select folders, check or remove saved access, choose future actions, and request launch at login. macOS may require login-item approval. Folder access uses app-scoped bookmarks and applies only to the containing app; no production Finder extension consumes these settings yet. Finder integration enablement, bookmark sharing across processes, folder selection and restored access in a signed app, and login-item behavior remain unverified. Initial product scope is local files on current macOS.

## Automated verification

Run `bash Tests/verify-app-bundle.sh` on a Mac with Xcode installed. It builds a fresh ad-hoc signed app and verifies the executable, bundle type, minimum version, accessory configuration, signature, sandbox, and hardened runtime. The check does not verify that the menu appears or that Quit works, nor does it test a Developer ID signature or execution on macOS 13. Those require interactive testing and appropriate signing credentials.

Run `bash Tests/verify-settings.sh` for isolated settings persistence, folder removal and invalid-bookmark handling. This does not replace interactive permission, login-item, and Finder extension testing.

Run `bash Tests/verify-finder-target.sh` for local file, folder, background and ambiguous-selection resolution. The standalone resolver is not yet wired to a production Finder extension. It rejects multiple selected items, missing paths and nonlocal volumes; resolves symbolic links; and requires its caller to verify folder authorization and revalidate access when performing an operation. Actual Finder integration, security-scoped access and behavior on cloud-backed volumes remain unverified.

Run `bash Tests/verify-file-creation.sh` to verify empty file and folder creation, validation, existing-item protection and concurrent name collisions. The creation service and native prompt are not yet connected to Finder; interactive prompting, sandbox folder authorization and end-to-end Finder actions remain unverified. The caller must hold security-scoped access to the target folder during creation.

Run `bash Tests/verify-terminal-launcher.sh` for URL handoff, special characters, invalid targets, missing Terminal, and launch failures. The launcher uses Launch Services to pass the directory URL to Terminal without interpolating shell commands or requesting Automation permission. A standalone unsandboxed probe returned successful handoff on this Mac; Terminal's working directory could not be inspected in this environment. A successful handoff does not establish the working directory. Sandboxed behavior, permission failures, and Finder integration remain unverified; the caller must hold folder access and report the localized error on failure.

The menu bar shell can also be built as a Swift package with Xcode command-line tools:

```sh
swift run MacUtility
```

Extension packaging and a distributable signed release are not implemented.

## Finder integration constraint

Apple documents Finder Sync for file synchronization apps and says it is not intended as a general tool for modifying Finder. Its contextual menu applies to monitored directories. Investigate Finder Sync and Services with a signed, sandboxed prototype, including background clicks, selected folders, permissions and distribution viability before choosing a solution. The placeholder prototype must not be represented as a supported integration.

See [the development plan](docs/DEVELOPMENT_PLAN.md) and [Apple's Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).

The [Finder integration research](docs/FINDER_INTEGRATION_RESEARCH.md) describes the diagnostic prototypes, automated packaging checks, and remaining manual feasibility work.

## Localization

The app follows the system language and includes English and Ukrainian; English is the development-language fallback. User-visible text is looked up through `L10n` and `Localizable.strings` resources. To add a language, create a new language `.lproj` directory in `Sources/MacUtility/Resources`, translate every key, and add it to the Xcode `Localizable.strings` variant group and known regions. Keep format placeholders compatible. Run `bash Tests/verify-localization.sh` and `bash Tests/verify-app-bundle.sh` after changing translations. Plural-sensitive text should use native `.stringsdict` resources when introduced.

Actual English and Ukrainian UI rendering, text truncation, VoiceOver, and language fallback should also be verified interactively; they have not yet been tested. The research-only Finder prototype is not localized.
