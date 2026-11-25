# Clicklet

[Website](https://clicklet.artembondar.dev/) · [Download](https://github.com/ArtemBondar/mac-utility/releases/latest)

## What

Clicklet is a lightweight Swift app that lives in the macOS menu bar and adds everyday file actions to Finder.

| Finder action | What it does |
| --- | --- |
| **New File** | Creates an empty file with the name and extension you enter. |
| **New Folder** | Creates a folder with the name you enter. |
| **Open Terminal Here** | Opens Terminal in the target folder, without a confirmation prompt. |
| **Copy Folder Path** | Copies the folder's absolute path to the clipboard, without a prompt. |

The app includes English and Ukrainian, an optional Dock icon, and launch at login.

## Why

Create a file, start a terminal session, or copy a folder path where you are already working. Clicklet keeps these actions in Finder's right-click menu, with settings available from the menu bar.

The direct-download app works with local folders your account can access, without asking you to add each folder individually. Normal macOS privacy controls and filesystem permissions still apply.

## How

### Install

The current download is for **Apple silicon Macs** and is tested on current macOS. Older macOS versions and Intel builds have not been verified.

1. Download [Clicklet-1.0.1.zip](https://github.com/ArtemBondar/mac-utility/releases/download/v1.0.1/Clicklet-1.0.1.zip), or visit [Releases](https://github.com/ArtemBondar/mac-utility/releases) for newer versions.
2. Quit any older copy of Clicklet, then unzip the download.
3. Move **Clicklet.app** to **Applications**. Keep one installed copy and open it from there.
4. If macOS blocks the first launch, note that this release is **ad-hoc signed and not notarized**. Review [Apple's guidance for opening downloaded apps](https://support.apple.com/en-us/102445) before deciding whether to allow it.
5. On first launch, choose **Open Finder Extension Settings** and enable Clicklet. You can also reach this button through the app's menu bar icon → **Settings…**.

The app's menu bar menu and Settings show whether the Finder extension is enabled. The Dock icon is hidden by default.

### Use

In Finder, right-click an empty area inside a local folder, or right-click a single file or folder, then choose a Clicklet action.

- **Folder background:** actions use the current folder.
- **Selected folder:** actions use that folder.
- **Selected file:** actions use its containing folder.

For **New File** and **New Folder**, enter a name and choose **Create**. Existing items are not overwritten. **Open Terminal Here** opens Terminal immediately; **Copy Folder Path** copies a plain absolute path that you can paste with **⌘V**.

Multiple selections are not supported. Protected folders may require macOS permission, and read-only locations cannot accept new items. Cloud and network locations are outside the tested scope.

### Settings

Choose the menu bar icon → **Settings…** to:

- Enable or disable **New File**, **New Folder**, and **Open Terminal Here**.
- Show or hide the Dock icon.
- Turn **Open at Login** on or off. macOS may require approval in Login Items settings.

The app follows your system language and falls back to English. To quit, choose **Quit Clicklet** from its menu bar menu.

### If Finder actions are missing

Confirm that the Finder extension is enabled through **Settings… → Open Finder Extension Settings**, and that you are clicking a local folder or a single item. After an update, quit older app copies and open the copy in Applications.

Finder can keep a development preview registered from another location. If you have a source checkout, select the intended Direct build with:

```sh
python3 scripts/activate_direct_preview.py /Applications/Clicklet.app
```

This verifies the app signature and refreshes only Clicklet Direct registrations. It preserves app files, preferences, extension enablement, and privacy permissions.

### Build and contribute

Open `MacUtility.xcodeproj` in Xcode and select the **MacUtility** scheme, **Direct** configuration, and **My Mac**. The Direct host runs outside App Sandbox; its Finder extension remains sandboxed. The sandboxed Debug/Release configurations require App Group provisioning and are not the configuration shipped in the GitHub download.

To build a local Direct ZIP, provide an output directory that does not exist:

```sh
bash scripts/build-direct-preview.sh /tmp/macutility-build
```

Run the automated checks on a Mac with Xcode installed:

```sh
bash scripts/ci-checks.sh
```

The GitHub Pages website lives in `site/`. To run its desktop and mobile browser tests:

```sh
npm ci
npx playwright install chromium
npm run test:site
```

Further details:

- [Verification results and remaining manual checks](docs/VERIFICATION.md)
- [CI and release workflow](docs/CI_CD.md)
- [Signing, notarization, and release preparation](docs/RELEASE.md)
- [Development plan](docs/DEVELOPMENT_PLAN.md)
- [Finder integration research](docs/FINDER_INTEGRATION_RESEARCH.md)

The app is written in Swift with native macOS UI. Translations live in `Sources/MacUtility/Resources/<language>.lproj/Localizable.strings`; run `bash Tests/verify-localization.sh` after changing them.
