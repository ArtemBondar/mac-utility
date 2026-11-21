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

The menu bar shell can also be built as a Swift package with Xcode command-line tools:

```sh
swift run MacUtility
```

Login launch, settings, extension packaging, and a distributable signed release are not implemented.

## Finder integration constraint

Apple documents Finder Sync for file synchronization apps and says it is not intended as a general tool for modifying Finder. Its contextual menu applies to monitored directories. Investigate Finder Sync and Services with a signed, sandboxed prototype, including background clicks, selected folders, permissions and distribution viability before choosing a solution. The placeholder prototype must not be represented as a supported integration.

See [the development plan](docs/DEVELOPMENT_PLAN.md) and [Apple's Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).
