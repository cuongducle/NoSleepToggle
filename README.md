# NoSleepToggle

NoSleepToggle is a small macOS menu bar app that keeps your Mac awake with one click.

The main goal is simple: keep your personal Mac running in the background for long tasks, especially when you want to host OpenClaw and do not want the machine to sleep after you close the lid.

## What It Does

- Keeps your Mac awake during long-running work
- Useful for hosting OpenClaw on your personal Mac
- Helps downloads, builds, scripts, and SSH sessions continue in the background
- Lives in the menu bar so you can turn it on or off instantly
- Can start automatically at login

When `No Sleep` is ON, the app applies:
- `pmset -a disablesleep 1`
- `caffeinate -dimsu`

## Best Use Cases

- Host OpenClaw on your personal Mac and keep it running in the background
- Close your Mac and let a long build keep running
- Keep large downloads from stopping halfway
- Keep remote SSH or terminal work alive
- Prevent sleep during presentations, installs, or background jobs

## Install

1. Download the latest `.zip` from [Releases](https://github.com/cuongducle/NoSleepToggle/releases).
2. Extract the `.zip` to get `NoSleepToggle.app`.
3. Open the app directly, or move it anywhere you want first.
4. Click the menu bar icon and turn `No Sleep` ON when you want your Mac to stay awake.

## Menu

- `No Sleep: ON/OFF`
- `Launch at Login: ON/OFF`
- `Refresh status`
- `Quit`

## Important Note

This app is meant for people who want their Mac to keep working instead of sleeping during long tasks, especially if the machine is being used as a lightweight personal host for something like OpenClaw.

Actual behavior can still depend on your specific Mac model, power setup, and macOS behavior.

## First Launch

Current builds are distributed as a `.zip` with an unsigned app bundle.

Why macOS may say the app cannot be opened:
- The release is not signed with Apple Developer ID
- The release is not notarized by Apple
- macOS Gatekeeper treats apps downloaded from the internet more strictly

If macOS blocks the app:
1. Right-click `NoSleepToggle.app` in Finder and choose `Open`.
2. If needed, go to `System Settings > Privacy & Security` and choose `Open Anyway`.

If you moved the app somewhere else, use that path instead of `Applications` in the command below.

Optional terminal workaround:

```bash
xattr -dr com.apple.quarantine /path/to/NoSleepToggle.app
```

## Build From Source

```bash
cd /Users/cuong/workspace/NoSleepToggle
./scripts/build_app.sh
open /Users/cuong/workspace/NoSleepToggle/dist/NoSleepToggle.app
```

## Developer Release

Push a tag that starts with `v` to create a GitHub Release automatically.
The release uploads a `.zip` containing `NoSleepToggle.app`.

```bash
git tag v1.0.1
git push origin v1.0.1
```
