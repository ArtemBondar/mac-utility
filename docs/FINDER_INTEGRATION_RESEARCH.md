# Finder integration feasibility

Status: **Finder Sync is the provisional implementation candidate; distribution and location coverage remain unverified**. This is a research build, not a production implementation.

## Decision and evidence

Continue with a narrowly scoped Finder Sync experiment as the leading candidate for the requested background and item context menus. Also evaluate Services as an alternative for selected files and folders. Do not commit the product architecture or promise App Store acceptance until the manual matrix below and a distribution review are completed. Services may require a different user experience, particularly for empty Finder backgrounds.

This is a provisional recommendation, not a claim that Apple endorses the use. Apple's [Finder Sync guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html) says the API supports monitored roots and their descendants, item and container menus, and exposes selected and targeted URLs during menu callbacks/actions. The same guide explicitly says Finder Sync is not intended as a general Finder UI modification tool. The guide is archived; check current platform behavior and policy before release. Apple's [Services property documentation](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/properties.html) describes `NSSendFileTypes`, `NSRequiredContext`, and file URLs on the pasteboard; it does not establish that a background click supplies a directory.

The developer of [QuickRight reports](https://www.reddit.com/r/MacOS/s/APqwtu65dh) using Finder Sync, with Shift-right-click needed for some cloud-backed folders. This is third-party evidence, not an independent verification, a universal rule, or assurance of review approval.

## Evidence collected

On macOS 27.2.1 (26B131), Apple silicon, Xcode 27.2 (27B52):

- `bash Tests/verify-finder-prototype.sh` compiled a diagnostic Services host and Finder Sync extension, ad-hoc signed both, verified signatures and sandbox entitlements, and checked registration metadata. This checks packaging, not actual host integration or UI behavior.
- In the command sandbox, `pluginkit -a` failed with `add: Connection invalid`. Outside that sandbox, registration and host launch succeeded; `pluginkit` listed the extension as enabled and its process was observed. The first prototype used `homeDirectoryForCurrentUser` inside the sandbox, and Finder Sync commands were absent. After changing the diagnostic root to the account home returned by `getpwuid`, Finder displayed the Finder Sync items for a file, folder, background, and a two-item selection under the disposable `~/MacUtilityPrototype` folder. This supports the root-path hypothesis but does not independently prove the first failure's cause.
- In those Finder Sync menu callbacks, `targetedURL` was the enclosing/displayed folder for all four contexts. `selectedItemURLs` contained the selected file, selected folder, both items, or the displayed folder for the background, respectively. These are observations for this OS and setup, not a guarantee for every Finder view or OS version. The diagnostic action's alert was not accessible; the values were observed in disabled diagnostic menu items during the callback.
- The Services action appeared directly in the selected file's contextual menu, and invoking it displayed the correct file URL. For the selected folder it appeared in the Services submenu. It did not appear in the background menu. Folder-service invocation and multiple-item Services execution were not tested.
- After the test, the extension was disabled and unregistered, the host's Launch Services registration was removed, the test processes were stopped, and the disposable file and folder were deleted. A subsequent `pluginkit` query returned no matches.
- `security find-identity -v -p codesigning` reported zero valid identities. No Developer ID signature, notarization, App Store submission, review, or installation on a clean account has been tested. Ad-hoc signing is not a distribution signature.
- No macOS 13 execution, user-selected folder permissions, cross-process bookmark access, Terminal automation, network volumes, removable disks, or cloud-provider behavior was tested. No performance or reliability claim can be made from this build.

## Context and setup matrix to complete

Record OS version, Finder version, build signing, sandbox configuration, enabled extensions, folder type, observed menu location, supplied URLs, and any errors for each case. Blank cells are **not yet tested**.

| Interaction | Finder Sync | Services |
|---|---|---|
| Right-click one ordinary file | Action visible; target was containing folder, selection was file | Action visible directly in the context menu; returned the sample file URL |
| Right-click one ordinary folder | Action visible; target was containing folder, selection was folder | Action visible under Services; invocation not tested |
| Right-click empty background of the intended test folder | Action visible; target and selection were displayed folder | Action not visible in this run |
| Multiple selected items | Action visible; target was containing folder, selection included both items | Action visible; invocation not tested |
| Folder outside monitored root | Not tested | Not tested |
| Cloud-backed item and background, normal and Shift-right-click | Not tested | Not tested |
| Read-only, removable, network and revoked-access locations | Not tested | Not tested |
| Finder setup/enablement and menu placement | Registered and enabled outside the command sandbox; item visible in tested contexts after root fix | Host launched; selected-file action appeared directly and selected-folder action under Services |

## Prototype and manual test procedure

`Research/FinderIntegration` is isolated from the shipping app. The host registers a diagnostic Service accepting file URLs; the extension registers the narrow `~/MacUtilityPrototype` account-home root and displays target and selected paths as disabled menu entries. Both expose received paths locally and do not create or modify user files. The host and extension are ad-hoc signed and sandboxed, with placeholder identifiers. The host has no Dock icon and no user-facing Quit control; quit it using Activity Monitor after testing. They are not suitable for distribution. The Finder extension's ability to show an alert is itself unverified. The fixed account-home path is only a diagnostic convenience; it is not a user authorization or a production access model.

1. Run `bash Tests/verify-finder-prototype.sh` for the noninteractive build and packaging checks. To retain a diagnostic app, run `bash Research/FinderIntegration/build.sh /tmp/macutility-research-output` with a **new**, nonexistent output path.
2. On a development Mac where plugin registration is allowed, arrange a real development signature and unique bundle identifiers if required; ad-hoc signing may not suffice. Create `~/MacUtilityPrototype` only if it does not already exist, with disposable sample files and a subfolder. Keep track of what you created.
3. Register/enable the extension using the appropriate system extension settings and launch the host so Services can register. System Settings wording varies by macOS release. Record the exact steps. If setup fails, record the error rather than treating it as a negative menu result.
4. Right-click the sample file, folder, and background; compare the disabled diagnostic menu entries with the intended target and selection. Repeat with multiple selection, an unrelated location, and supported cloud/network/removable locations. For Services inspect the selected file/folder in Finder's Services context. Record actual placement and missing cases.
5. Disable/unregister the research extension and quit the host. Remove only sample files and folders created for the test, and delete the generated research app. Confirm that the production app and other extensions remain unchanged.

The script does not install or register anything. A real test must assess whether an app can obtain and retain the minimum folder access it needs. Apple documents [user-selected folders, sandbox access and bookmarks](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox); do not assume an app-scoped bookmark can simply be shared across processes. Prove cross-process access with the actual signing and entitlements used in the selected design.

## Distribution constraints

The [Mac App Store requires App Sandbox](https://developer.apple.com/macos/distribution), and [App Review guideline 4.4](https://developer.apple.com/app-store/review/guidelines/) applies to extension-containing apps. Finder Sync's documented intended use creates an unresolved review risk for this utility, even though a similar app exists. Apple's [Developer ID and notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) describes the direct-download signing and notarization workflow. Notarization is not App Review and cannot establish App Store suitability. Evaluate both distribution paths with production identifiers, capabilities, signing, and a clean-account install before making release commitments.
