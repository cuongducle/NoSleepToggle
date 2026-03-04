# NoSleepToggle

Menu bar app to toggle:

`sudo pmset -a disablesleep 1` / `0`

## Build app bundle

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/build_app.sh
./scripts/build_app.sh
```

App output:

`/Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app`

## Run

```bash
open /Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app
```

You will see an icon on the right side of the top bar. Click it to:

- Turn On No Sleep (set 1)
- Turn Off No Sleep (set 0)
- Refresh status
- Quit

The toggle action prompts for admin password via macOS.

## Build DMG installer

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/create_dmg.sh
./scripts/create_dmg.sh
```

DMG output:

`/Users/cuong/workspace/NoSleepToggle/release/NoSleepToggle.dmg`

## Sign + notarize DMG (Developer ID)

Prerequisites:

- Apple Developer Program account
- Developer ID Application certificate installed in your keychain
- Notary profile saved with `notarytool`

Store notary credentials once:

```bash
xcrun notarytool store-credentials "NoSleepNotary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID"
```

Run signing + notarization:

```bash
cd /Users/cuong/workspace/NoSleepToggle
chmod +x scripts/sign_and_notarize.sh
CODESIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAMID)" \
NOTARY_PROFILE="NoSleepNotary" \
./scripts/sign_and_notarize.sh
```
