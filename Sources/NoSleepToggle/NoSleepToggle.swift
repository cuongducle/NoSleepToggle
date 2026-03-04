import AppKit
import Foundation

enum SleepState {
    case on
    case off
    case unknown
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let toggleItem = NSMenuItem(title: "No Sleep: UNKNOWN", action: #selector(toggleSleep), keyEquivalent: "t")
    private var caffeinateProcess: Process?

    private var sleepState: SleepState = .unknown {
        didSet {
            updateUI()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        menu.addItem(NSMenuItem(title: "Refresh status", action: #selector(refreshStatusAction), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }

        statusItem.menu = menu
    }

    @objc private func refreshStatusAction() {
        refreshStatus()
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
