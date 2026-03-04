# NoSleepToggle

Small macOS menu bar app to quickly turn `No Sleep` on/off.

When ON, the app applies:
- `pmset -a disablesleep 1`
- `caffeinate -dimsu` (Awake Guard)

When OFF, it restores:
- `pmset -a disablesleep 0`
- stops Awake Guard

## Quick Install (recommended)

1. Download latest `.dmg` from [Releases](https://github.com/cuongducle/NoSleepToggle/releases).
2. Open DMG and drag `NoSleepToggle.app` into `Applications`.
3. Open app and click the menu bar icon (top-right).

Menu actions:
- `Turn On No Sleep (set 1)`
- `Turn Off No Sleep (set 0)`
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
