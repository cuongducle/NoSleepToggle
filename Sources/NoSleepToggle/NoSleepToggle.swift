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
    private let stateItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
    private let turnOnItem = NSMenuItem(title: "Turn On No Sleep (set 1)", action: #selector(turnOnNoSleep), keyEquivalent: "")
    private let turnOffItem = NSMenuItem(title: "Turn Off No Sleep (set 0)", action: #selector(turnOffNoSleep), keyEquivalent: "")
    private let toggleItem = NSMenuItem(title: "Toggle", action: #selector(toggleSleep), keyEquivalent: "t")

    private var sleepState: SleepState = .unknown {
        didSet {
            updateUI()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        refreshStatus()
    }

    private func setupMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "No Sleep")
            button.imagePosition = .imageOnly
        }

        let menu = NSMenu()
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())
        menu.addItem(turnOnItem)
        menu.addItem(turnOffItem)
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

    @objc private func turnOnNoSleep() {
        setDisableSleep(1)
    }

    @objc private func turnOffNoSleep() {
        setDisableSleep(0)
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
                sleepState = .unknown
                showAlert(title: "Cannot update setting", message: "Command failed: \(command)")
            }
        } catch {
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
        process.arguments = ["-g", "custom"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            sleepState = parseDisableSleep(from: text)
        } catch {
            sleepState = .unknown
        }
    }

    private func parseDisableSleep(from text: String) -> SleepState {
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("disablesleep") {
                let pieces = trimmed.split(whereSeparator: \.isWhitespace)
                if let last = pieces.last, let value = Int(last) {
                    return value == 1 ? .on : .off
                }
            }
        }
        return .unknown
    }

    private func updateUI() {
        switch sleepState {
        case .on:
            stateItem.title = "Status: ON (No Sleep)"
            toggleItem.title = "Toggle -> Turn Off"
            turnOnItem.isEnabled = false
            turnOffItem.isEnabled = true
        case .off:
            stateItem.title = "Status: OFF (Allow Sleep)"
            toggleItem.title = "Toggle -> Turn On"
            turnOnItem.isEnabled = true
            turnOffItem.isEnabled = false
        case .unknown:
            stateItem.title = "Status: UNKNOWN"
            toggleItem.title = "Toggle -> Turn On"
            turnOnItem.isEnabled = true
            turnOffItem.isEnabled = true
        }
        if let button = statusItem.button {
            let symbol: String
            switch sleepState {
            case .on:
                symbol = "bolt.horizontal.circle.fill"
            case .off:
                symbol = "moon.zzz"
            case .unknown:
                symbol = "questionmark.circle"
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
