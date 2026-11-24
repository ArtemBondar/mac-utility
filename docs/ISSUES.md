# Implementation issue backlog

Each section is intended to become a separate GitHub issue. The feasibility issue is a prerequisite for choosing the final integration and distribution scope.

## 1. Validate Finder integration and distribution options

Compare signed prototypes of Finder Sync and Services for selected files, folders, and Finder backgrounds. Investigate sandbox permissions and direct-download and App Store suitability, accounting for Apple's stated intended use of Finder Sync.

**Acceptance criteria**
- Record supported contexts, actual menu placement, setup and OS versions tested.
- Record access and distribution constraints, including unresolved review risks.
- Decide on an integration or document a proposed scope change before implementation proceeds.

## 2. Package and sign the menu bar application

Create an installable macOS app target with the SwiftUI menu bar shell and appropriate signing configuration.

**Acceptance criteria**
- A signed app bundle launches with a menu bar icon and no persistent Dock icon.
- Quit works and the app runs on the selected minimum macOS version.
- Document build and signing instructions without committing credentials.

## 3. Add onboarding, settings and folder access

Provide native setup for enabling the chosen integration and authorizing locations. Persist settings and access as appropriate to the chosen architecture.

**Acceptance criteria**
- Users can configure supported folders and individual actions.
- Explain integration status and permission requests; handle revoked or stale access.
- Settings persist after restart, and optional launch at login can be toggled.

## 4. Implement Finder target resolution

Determine the intended folder for supported Finder contexts using the chosen integration.

**Acceptance criteria**
- Selected folders target themselves; selected files target their parent.
- Background clicks target the displayed folder where supported.
- Multiple selections and unsupported locations have documented, predictable behavior.

## 5. Create files and folders safely

Add native prompts and creation operations for the resolved folder.

**Acceptance criteria**
- New File creates an empty file with the requested name; New Folder creates a directory.
- Existing items are never silently overwritten, including under concurrent creation.
- Invalid names, cancellation, permission failures and unavailable locations are handled clearly.

## 6. Open Terminal in the target folder

Implement and validate the supported way to start Apple Terminal in the target directory.

**Acceptance criteria**
- Terminal opens at the correct directory for names with spaces and special characters.
- Any required Automation permission is explained; denial has a useful recovery path.
- The implementation safely handles paths and documents sandbox limitations.

## 7. Verify accessibility, robustness and performance

Test the app and integration under realistic conditions and address findings.

**Acceptance criteria**
- Verify light/dark appearance, keyboard navigation and VoiceOver labels.
- Test read-only, removable, network and cloud locations where supported, plus revoked access.
- Measure idle CPU and memory; remove unnecessary polling and record results.

## 8. Prepare signed and notarized release

Prepare the chosen distribution, installation and support materials after the feasibility decision.

**Acceptance criteria**
- Build, sign and notarize a release and test installation on a clean account.
- Document enabling the integration, permissions, supported contexts, troubleshooting and uninstall.
- Record App Store suitability separately; do not claim approval without verification.
