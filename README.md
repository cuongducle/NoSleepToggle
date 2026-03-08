# NoSleepToggle

NoSleepToggle is a small macOS menu bar app that keeps your Mac awake with one click.

The main goal is simple: start a long task, turn `No Sleep` on, close your Mac, and let it keep running instead of going to sleep.

## What It Does

- Keeps your Mac awake during long-running work
- Helps downloads, builds, scripts, and SSH sessions continue in the background
- Lives in the menu bar so you can turn it on or off instantly
- Can start automatically at login

When `No Sleep` is ON, the app applies:
- `pmset -a disablesleep 1`
- `caffeinate -dimsu`

## Best Use Cases

- Close your Mac and let a long build keep running
- Keep large downloads from stopping halfway
- Keep remote SSH or terminal work alive
- Prevent sleep during presentations, installs, or background jobs

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/cuongducle/NoSleepToggle/releases).
2. Open the DMG and drag `NoSleepToggle.app` into `Applications`.
3. Launch the app and click the menu bar icon.
4. Turn `No Sleep` ON when you want your Mac to stay awake.

## Menu

- `No Sleep: ON/OFF`
- `Launch at Login: ON/OFF`
- `Refresh status`
- `Quit`

## Important Note

This app is meant for people who want their Mac to keep working instead of sleeping during long tasks, including the common workflow of closing the lid and walking away.

Actual behavior can still depend on your specific Mac model, power setup, and macOS behavior.

## First Launch

Current builds may be unsigned.

If macOS blocks the app:
1. Right-click `NoSleepToggle.app` in Finder and choose `Open`.
2. If needed, go to `System Settings > Privacy & Security` and choose `Open Anyway`.

Optional terminal workaround:

```bash
xattr -dr com.apple.quarantine /Applications/NoSleepToggle.app
```

## Build From Source

```bash
cd /Users/cuong/workspace/NoSleepToggle
./scripts/build_app.sh
open /Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app
```

## Developer Release

Push a tag that starts with `v` to create a GitHub Release automatically.

```bash
git tag v1.0.1
git push origin v1.0.1
```
