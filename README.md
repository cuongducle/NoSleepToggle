# NoSleepToggle

Small macOS menu bar app to quickly turn `No Sleep` on/off.
The menu now always shows a simple `ON/OFF` state (no `UNKNOWN` label).

When ON, the app applies:
- `pmset -a disablesleep 1`
- `caffeinate -dimsu` (Awake Guard)

When OFF, it restores:
- `pmset -a disablesleep 0`
- stops Awake Guard

## Use Cases

- Prevent sleep during long builds
- Prevent sleep during downloads
- Keep Mac awake during SSH sessions

## GitHub Topics

Suggested repository topics:
- `macos`
- `menu-bar`
- `utility`
- `developer-tools`
- `nosleep`
- `swift`

## Quick Install (recommended)

1. Download latest `.dmg` from [Releases](https://github.com/cuongducle/NoSleepToggle/releases).
2. Open DMG and drag `NoSleepToggle.app` into `Applications`.
3. Open app and click the menu bar icon (top-right).
4. The app auto-enables `Launch at Login` so it starts on the next login.

Menu actions:
- `No Sleep: ON/OFF` (single toggle button)
- `Launch at Login: ON/OFF`
- `Refresh status`
- `Quit`

## First Launch Warning (unsigned app)

This project currently ships as unsigned/not-notarized builds.

If macOS blocks launch:
1. Right-click `NoSleepToggle.app` in Finder -> `Open`.
2. If still blocked: `System Settings > Privacy & Security` -> `Open Anyway`.

Optional terminal workaround:

```bash
xattr -dr com.apple.quarantine /Applications/NoSleepToggle.app
```

## Build From Source

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/build_app.sh
./scripts/build_app.sh
open /Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app
```

Output app:
- `/Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app`

## Build DMG

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

Output DMG:
- `/Users/cuong/workspace/NoSleepToggle/release/NoSleepToggle.dmg`

## Release

GitHub Actions is configured to build and publish a release whenever you push a tag that starts with `v`.

Example:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The workflow will:
- build `NoSleepToggle.app`
- create a release DMG
- upload both `.zip` and `.dmg` assets to the GitHub Release page

## Optional: Sign + Notarize (paid Apple Developer account)

Prerequisites:
- `Developer ID Application` certificate in keychain
- notary profile configured with `notarytool`

Store credentials once:

```bash
xcrun notarytool store-credentials "NoSleepNotary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID"
```

Run signing pipeline:

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/sign_and_notarize.sh
CODESIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAMID)" \
NOTARY_PROFILE="NoSleepNotary" \
./scripts/sign_and_notarize.sh
```
