# Development plan

## Goal and scope

Build a lightweight native Swift macOS menu bar utility for creating a file or folder and opening Terminal at a Finder location. Use native controls, system appearance, accessible labels and minimal idle activity. Target macOS 13 or later initially; review deployment target during release planning.

## Feasibility gate

Apple describes Finder Sync as an extension for synchronization apps and explicitly says it is not intended as a general Finder UI modification tool. Before committing to an architecture or distribution channel, compare Finder Sync and macOS Services with signed prototypes. Test selected folders, files, Finder background clicks, sandbox access, menu placement, setup, and direct and Mac App Store distribution. Document limitations and select a supported product scope. The stub in this repository is not a working extension.

## MVP behavior

- New File: prompt for a name and create an empty file without overwriting.
- New Folder: prompt for a name and create it without overwriting.
- Open Terminal Here: open Apple Terminal at the target location, including paths containing special characters.
- Folder target: the selected folder; file target: its parent; Finder background: the displayed folder when supported by the integration. Define behavior for multiple selections and unsupported locations during the feasibility gate.
- Menu bar: integration status, settings, help, and quit. Settings should include supported locations, enabled actions, and an optional login launch.
- Explain enablement and folder access; report errors clearly. Avoid blanket permissions where narrower access suffices.

## Architecture

SwiftUI menu bar and settings, with AppKit where needed. Use Foundation for file operations. The chosen integration will be a separate target when appropriate. Use an App Group only when shared state is needed; persist user-selected folder access with security-scoped bookmarks when required. Validate cross-process access rather than assuming bookmark portability. Investigate a supported Terminal launch mechanism, Automation permissions, and sandbox restrictions. Do not interpolate paths into shell commands unsafely.

## Milestones

1. **Feasibility (2–4 days):** compare integration mechanisms and Terminal launch in signed prototypes; record behavior and distribution risks.
2. **Foundation (2–3 days):** app bundle, signing, settings, onboarding, integration enablement and folder authorization.
3. **Actions (3–5 days):** target resolution, safe creation, Terminal integration and useful errors.
4. **Polish and verification (3–5 days):** accessibility, appearance, permissions, location types, reliability and idle resource profiling.
5. **Release (1–2 days):** clean-account installation, signing, notarization, user documentation and distribution.

Estimates are for one developer and depend on the feasibility findings.

## Release checks

Confirm the integration works in each supported Finder context; duplicate names never overwrite; denied permissions and read-only locations are handled; Terminal starts in the correct directory; light/dark appearance, keyboard navigation and VoiceOver work; login launch and uninstall behave correctly; and the signed release installs on a clean account. Test local, removable, network and cloud-backed folders where supported. Record limitations rather than implying universal coverage.

## References

- [Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)
- [Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [Menu bar design](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Apple Events entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events)
