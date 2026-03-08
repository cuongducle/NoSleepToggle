import AppKit
import Foundation

enum SleepState {
    case on
    case off
    case unknown
}

struct LaunchAtLoginManager {
    private static let label = "com.cuong.nosleeptoggle"

    static func isEnabled() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func syncEnabled() {
        guard let appBundlePath = appBundlePath else {
            return
        }

        if !isEnabled() {
            try? enable(appBundlePath: appBundlePath)
        } else {
            try? update(appBundlePath: appBundlePath)
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard let appBundlePath = appBundlePath else {
            throw LaunchAtLoginError.invalidBundlePath
        }

        if enabled {
            try enable(appBundlePath: appBundlePath)
        } else {
            try disable()
        }
    }

    private static var plistURL: URL {
        let launchAgentsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents", isDirectory: true)
        return launchAgentsURL.appendingPathComponent("\(label).plist")
    }

    private static var appBundlePath: String? {
        let bundlePath = Bundle.main.bundleURL.path
        return bundlePath.hasSuffix(".app") ? bundlePath : nil
    }

    private static func enable(appBundlePath: String) throws {
        try update(appBundlePath: appBundlePath)
    }

    private static func update(appBundlePath: String) throws {
        let launchAgentsURL = plistURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        let plist = makePropertyList(appBundlePath: appBundlePath)
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)
    }

    private static func disable() throws {
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    private static func makePropertyList(appBundlePath: String) -> [String: Any] {
        [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", "-a", appBundlePath],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]
    }
}

enum LaunchAtLoginError: LocalizedError {
    case invalidBundlePath

    var errorDescription: String? {
        switch self {
        case .invalidBundlePath:
            return "Launch at Login only works when the app is running from a .app bundle."
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let toggleItem = NSMenuItem(title: "No Sleep: UNKNOWN", action: #selector(toggleSleep), keyEquivalent: "t")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login: ON", action: #selector(toggleLaunchAtLogin), keyEquivalent: "l")
    private var caffeinateProcess: Process?

    private var sleepState: SleepState = .unknown {
        didSet {
            updateUI()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLoginManager.syncEnabled()
        setupMenu()
        refreshStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopAwakeGuard()
    }

    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "No Sleep")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        menu.addItem(toggleItem)
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem(title: "Refresh status", action: #selector(refreshStatusAction), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        statusItem.menu = menu
    }

    @objc private func refreshStatusAction() {
        refreshStatus()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLoginManager.setEnabled(!LaunchAtLoginManager.isEnabled())
            updateUI()
        } catch {
            showAlert(title: "Cannot update Launch at Login", message: error.localizedDescription)
        }
    }

    @objc private func toggleSleep() {
        let targetValue: Int
        switch sleepState {
        case .on:
            targetValue = 0
        case .off, .unknown:
            targetValue = 1
        }
        setDisableSleep(targetValue)
    }

    private func setDisableSleep(_ targetValue: Int) {
        let command = "pmset -a disablesleep \(targetValue)"
        let script = "do shell script \"\(command)\" with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                refreshStatus()
            } else {
                stopAwakeGuard()
                sleepState = .unknown
                showAlert(title: "Cannot update setting", message: "Command failed: \(command)")
            }
        } catch {
            stopAwakeGuard()
            sleepState = .unknown
            showAlert(title: "Cannot update setting", message: error.localizedDescription)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func refreshStatus() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            sleepState = parseSleepDisabled(from: text)
            syncAwakeGuard()
        } catch {
            stopAwakeGuard()
            sleepState = .unknown
        }
    }

    private func syncAwakeGuard() {
        switch sleepState {
        case .on:
            startAwakeGuard()
        case .off, .unknown:
            stopAwakeGuard()
        }
        updateUI()
    }

    private func startAwakeGuard() {
        if let process = caffeinateProcess, process.isRunning {
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-dimsu"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            caffeinateProcess = process
        } catch {
            caffeinateProcess = nil
            showAlert(title: "Cannot start Awake Guard", message: error.localizedDescription)
        }
    }

    private func stopAwakeGuard() {
        guard let process = caffeinateProcess else {
            return
        }

        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        caffeinateProcess = nil
    }

    private func parseSleepDisabled(from text: String) -> SleepState {
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lower = trimmed.lowercased()
            if lower.hasPrefix("sleepdisabled") {
                let pieces = trimmed.split(whereSeparator: \.isWhitespace)
                if let last = pieces.last {
                    if last == "1" {
                        return .on
                    }
                    if last == "0" {
                        return .off
                    }
                }
            }
        }
        return .unknown
    }

    private func updateUI() {
        switch sleepState {
        case .on:
            toggleItem.title = "No Sleep: ON (Click to turn OFF)"
        case .off, .unknown:
            toggleItem.title = "No Sleep: OFF (Click to turn ON)"
        }

        launchAtLoginItem.title = LaunchAtLoginManager.isEnabled()
            ? "Launch at Login: ON"
            : "Launch at Login: OFF"

        if let button = statusItem.button {
            let symbol: String
            switch sleepState {
            case .on:
                symbol = "bolt.horizontal.circle.fill"
            case .off:
                symbol = "moon.zzz"
            case .unknown:
                symbol = "moon.zzz"
            }
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "No Sleep")
        }
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}

@main
enum NoSleepToggle {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
        _ = delegate
    }
}
