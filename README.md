# Mac Utility

A lightweight macOS menu bar utility in early development. The intended Finder actions are New File, New Folder, and Open Terminal Here.

## Current state

The SwiftUI menu bar shell builds and runs on macOS 13 or later. It does **not** yet install Finder commands or perform file operations. `FinderSyncPrototype/` contains an unbundled research stub; it is not an enabled Finder extension. The first milestone is to validate an appropriate integration before committing to the implementation.

## Run the shell

Install Xcode and its command-line tools, then run:

```sh
swift run MacUtility
```

The app runs as an accessory without a Dock icon. Use its menu bar icon to quit. A distributable `.app`, code signing, login launch, settings, and extension packaging are not implemented.

## Finder integration constraint

Apple documents Finder Sync for file synchronization apps and says it is not intended as a general tool for modifying Finder. Its contextual menu applies to monitored directories. Investigate Finder Sync and Services with a signed, sandboxed prototype, including background clicks, selected folders, permissions and distribution viability before choosing a solution. The placeholder prototype must not be represented as a supported integration.

See [the development plan](docs/DEVELOPMENT_PLAN.md) and [Apple's Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html).
