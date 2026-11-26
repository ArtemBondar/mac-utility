# Release preparation

Version 1.0.2 uses the Direct configuration for local files and folders on current macOS. It includes Finder file/folder creation, Terminal, and path copying. The GitHub artifact is ad-hoc signed and not notarized. Developer ID distribution and clean-account installation remain separate validation work.

## Read-only preflight

Run `python3 scripts/release_preflight.py`. The script checks for the project's placeholder bundle identifier and a valid Developer ID Application identity in the current keychain. It returns 1 for those blockers and 2 if it cannot inspect prerequisites. It neither builds nor signs, notarizes, uploads, or installs anything. A zero result is not a release approval: it does not inspect build-setting overrides, provisioning, account credentials, extension readiness, notarization or App Store review.

Run `python3 -m unittest discover -s Tests -p 'test_release_preflight.py'` to test the identity parser. Run the app and feature verification scripts listed in the README before preparing a candidate.

## Direct distribution checklist

1. Complete production Finder integration and verify local file and folder actions, security-scoped access, revoked access, and Terminal's working directory. Verify current macOS, English and Ukrainian UI, accessibility, and the login-item behavior. Record results and limitations.
2. Set an identifier owned by your developer team, configure Xcode signing, and provide a valid Developer ID Application identity and required provisioning. Keep signing credentials and notarization credentials out of the repository. The sample identifier is a placeholder.
3. Archive the actual release build, including any nested extension, with Developer ID and hardened runtime. Verify signatures and entitlements of the exported app and nested code. Do not mistake an ad-hoc development signature for a distribution signature.
4. Submit the exported artifact to Apple's notary service using Xcode or `notarytool`; inspect the result and log. Staple and validate the ticket on a supported artifact, and verify the distributed artifact with Gatekeeper. A ZIP can be submitted but cannot itself be stapled; see Apple's workflow for the applicable artifact.
5. On a clean macOS account, download and install the actual artifact, enable Finder integration, grant and revoke access, exercise each action and both languages, and verify quit, login-item settings, and removal. Record the OS version, artifact and results.
6. Verify user-facing installation, permissions, troubleshooting, supported-context, and uninstall instructions against the final artifact. These checks are required before claiming Developer ID signed and notarized distribution.

## App Store assessment

App Store distribution is a separate path requiring App Sandbox and App Review. Apple documents Finder Sync for synchronization apps rather than general Finder modification. The precedent of a similar app does not establish approval for this app. No App Store submission or review has occurred. Determine suitability using the final implementation and Apple's current requirements.

## References

- [Apple: distributing software on macOS](https://developer.apple.com/macos/distribution/)
- [Apple: notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple: customizing notarization](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [Apple: Finder Sync extension guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)
