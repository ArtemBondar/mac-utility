# Broad local Finder access

## Product requirement

Offer the three Finder actions across local files and folders without requiring the person to add each folder individually. The current Finder Sync implementation monitors saved, user-selected roots, and the host only performs actions within those grants. It therefore does **not** yet satisfy this requirement.

## What needs to be proved

Finder Sync registration and filesystem authorization are separate. Registering a broad root with `directoryURLs` could make menus available in its descendants, but registration does not give the app permission to write there. Test actual menu coverage for the user home, local data volume and mounted local volumes, including Finder backgrounds; do not assume a single root covers mounted volumes, protected paths or every Finder view. Apple's [Finder Sync documentation](https://developer.apple.com/documentation/findersync/fifindersynccontroller/directoryurls) specifies notifications for configured directories and descendants.

The app is currently sandboxed. Apple documents that a folder explicitly selected in an Open panel can grant sandbox access to descendants, subject to other restrictions. One user-selected broad folder could reduce repetitive setup, but whether the intended home or volume can be selected, restored, and used for all required local contexts must be tested on the target macOS version. It still requires a selection, so it is a fallback to assess, not fulfillment of the no-folder-selection goal. See [Apple's App Sandbox file access guide](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox).

Full Disk Access is a user-controlled macOS privacy setting, not a programmatic grant. It does not bypass the app sandbox; Apple Developer Technical Support explicitly [describes that distinction](https://developer.apple.com/forums/thread/807142). It also does not override filesystem permissions or System Integrity Protection. Do not promise that enabling it makes every location writable or request it before proving it is necessary.

## Next experiment

1. Compare a sandboxed signed build using explicit broad folder authorization with a separately configured, signed direct-distribution prototype without App Sandbox. Keep identifiers, capabilities, data and test artifacts isolated; do not silently weaken the shipping app's sandbox.
2. For each prototype, test local home folders, a local location outside the home, and an attached local volume. Record Finder menu availability independently from the ability to create files and folders and launch Terminal. Include normal, protected, read-only and unavailable locations, and restart/revocation behavior.
3. Record every user approval actually required, whether the app has to add folders individually, how monitoring roots and new local volumes are discovered, and the effect on idle resource use. No persistent monitoring or broad permission should be requested without an understandable reason.
4. Evaluate direct-distribution signing and notarization separately from App Store suitability. Apple [requires App Sandbox for Mac App Store distribution](https://developer.apple.com/documentation/security/app-sandbox); Finder Sync is documented for sync apps and has an unresolved review risk for this utility.
5. Choose the approach only after those tests. Report unsupported locations and permission failures clearly. Local-only support does not include cloud or network volumes in the initial scope.

## Verification status

The earlier sandboxed prototype exposed Finder Sync menus for selected items and background inside one test root on macOS 27.2.1. It did not validate broad-root coverage, access without folder selection, direct-distribution signing, or the behavior of protected local folders. A signed App Group configuration is still needed for end-to-end testing of the current implementation.
