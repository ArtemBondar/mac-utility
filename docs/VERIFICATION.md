# Accessibility, robustness and performance verification

Scope: current macOS and local Finder files and folders. This report describes the current app shell, not a production Finder extension, which is not yet implemented.

## Automated checks

On macOS 27.2.1 (26B131), Apple silicon, the settings, Finder target resolver, file creation, Terminal launcher, localization, release-preflight and app-bundle checks passed. Run their `Tests/verify-*.sh` scripts and `python3 -m unittest discover -s Tests -p test_release_preflight.py` for a regression pass. These checks do not prove Finder integration, accessibility, or runtime permission behavior.

Folder action accessibility labels now include their folder paths and have English and Ukrainian translations. Restored folder bookmarks are rejected when the path no longer identifies a directory. These changes do not establish full VoiceOver support.

## Sample idle measurement

A locally built, ad-hoc signed Debug app was started directly, with no Finder extension and no interaction. One `ps` sample after eight seconds showed 0.2% CPU and 86,368 KiB resident memory on an Apple silicon Mac running macOS 27.2.1. The temporary process was terminated afterward. This is a single snapshot, not a sustained benchmark or a release-build measurement; it includes startup effects and cannot establish a performance target.

## Remaining manual checks

- Verify menu and settings in light and dark appearance, keyboard-only navigation, VoiceOver labels and announcements, and long folder paths in both languages.
- Verify add, revoke, restore and remove folder access using a signed sandboxed app, including a read-only local folder and a renamed or replaced folder. Ensure errors are understandable.
- Once the production extension exists, test actual Finder actions, permissions, responsiveness and memory/CPU with the extension enabled. Also verify Terminal's working directory and login item behavior.
- Measure an idle Release build over a longer interval and record machine, OS, sample method, CPU, memory and energy impact. Repeat after integrating Finder; investigate polling or persistent background activity.

Older macOS versions and cloud and network files are outside the initial scope. No App Store review, Developer ID distribution signature, or clean-account installation has been verified.
