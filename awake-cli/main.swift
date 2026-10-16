import Foundation
import IOKit.pwr_mgt

let version = "1.0.0"

// MARK: - Distributed Notification Helpers

func postDistributedNotification(name: String) {
    let center = DistributedNotificationCenter.default()
    center.postNotificationName(
        NSNotification.Name(name),
        object: nil,
        userInfo: nil,
        deliverImmediately: true
    )
}

// MARK: - Assertion Management

var activeAssertionID: IOPMAssertionID = 0

func acquireAssertion(preventDisplaySleep: Bool, reason: String) -> Bool {
    let assertionType = preventDisplaySleep
        ? kIOPMAssertionTypePreventUserIdleDisplaySleep
        : kIOPMAssertionTypePreventUserIdleSystemSleep

    let result = IOPMAssertionCreateWithName(
        assertionType as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        reason as CFString,
        &activeAssertionID
    )
    return result == kIOReturnSuccess
}

func releaseAssertion() {
    if activeAssertionID != 0 {
        IOPMAssertionRelease(activeAssertionID)
        activeAssertionID = 0
    }
}

// MARK: - Duration Parser

func parseDuration(_ str: String) -> TimeInterval? {
    let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if trimmed.hasSuffix("h") {
        let val = Double(trimmed.dropLast()) ?? 0
        return val * 3600
    } else if trimmed.hasSuffix("m") {
        let val = Double(trimmed.dropLast()) ?? 0
        return val * 60
    } else if trimmed.hasSuffix("s") {
        return Double(trimmed.dropLast())
    } else if let num = Double(trimmed) {
        // Default to minutes if no suffix
        return num * 60
    }
    return nil
}

func formatDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    let seconds = Int(interval) % 60
    if hours > 0 {
        return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
    } else if minutes > 0 {
        return String(format: "%dm %02ds", minutes, seconds)
    } else {
        return String(format: "%ds", seconds)
    }
}

// MARK: - Help Banner

func printHelp() {
    print("""
    \u{001B}[1m\u{001B}[33m⚡️ Awake CLI\u{001B}[0m v\(version) — Mac Keep-Awake Utility

    \u{001B}[1mUSAGE:\u{001B}[0m
      awake [options] [command [args...]]

    \u{001B}[1mCOMMAND WRAPPER:\u{001B}[0m
      Keep your Mac awake while executing any long-running command:
        \u{001B}[36mawake npm run build\u{001B}[0m
        \u{001B}[36mawake docker compose up\u{001B}[0m
        \u{001B}[36mawake -d make test\u{001B}[0m              (also keeps display awake)

    \u{001B}[1mDURATION KEEP-AWAKE:\u{001B}[0m
      Keep your Mac awake for a specified timer:
        \u{001B}[36mawake -t 30m\u{001B}[0m                    (keep awake for 30 minutes)
        \u{001B}[36mawake -t 2h -d\u{001B}[0m                  (keep display & Mac awake for 2 hours)

    \u{001B}[1mAPP CONTROL & STATUS:\u{001B}[0m
      Communicate with the Awake menu bar app:
        \u{001B}[36mawake --on\u{001B}[0m                      Start indefinite keep-awake in Awake app
        \u{001B}[36mawake --off\u{001B}[0m                     Stop active session in Awake app
        \u{001B}[36mawake status\u{001B}[0m                    Display live session and system sleep status

    \u{001B}[1mOPTIONS:\u{001B}[0m
      -d, --display            Prevent display from sleeping or dimming
      -t, --time <duration>    Duration (e.g. 15m, 30m, 1h, 45s)
      -h, --help               Show this help message
      -v, --version            Display version information
    """)
}

// MARK: - Status Handler

func showStatus() {
    print("\u{001B}[1m\u{001B}[33m⚡️ Awake Status\u{001B}[0m")

    let statusPath = "/tmp/awake-status.json"
    if let data = FileManager.default.contents(atPath: statusPath),
       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        let isRunning = (json["isRunning"] as? Bool) ?? false
        let mode = (json["mode"] as? String) ?? "idle"
        let remaining = (json["remainingSeconds"] as? Double) ?? 0
        let display = (json["preventDisplaySleep"] as? Bool) ?? false
        let presentation = (json["isPresentationActive"] as? Bool) ?? false

        if isRunning {
            let modeTitle = presentation ? "\u{001B}[35mPresentation Mode\u{001B}[0m" : (mode == "unlimited" ? "\u{001B}[32mIndefinite Keep-Awake\u{001B}[0m" : "\u{001B}[32mTimer Active\u{001B}[0m")
            print("  Awake App:       \(modeTitle)")
            if mode == "timer" && remaining > 0 {
                print("  Time Remaining:  \(formatDuration(remaining))")
            }
            print("  Display Sleep:   \(display ? "\u{001B}[33mPrevented (Display Awake)\u{001B}[0m" : "Normal")")
        } else {
            print("  Awake App:       \u{001B}[90mIdle\u{001B}[0m")
        }
    } else {
        print("  Awake App:       \u{001B}[90mNot running or idle\u{001B}[0m")
    }

    // Check system power assertions
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    task.arguments = ["-g", "assertions"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()

    let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    if out.contains("PreventUserIdleSystemSleep") || out.contains("PreventUserIdleDisplaySleep") {
        print("  System Sleep:    \u{001B}[32mActive sleep prevention assertion detected\u{001B}[0m")
    } else {
        print("  System Sleep:    \u{001B}[90mStandard macOS energy saver rules active\u{001B}[0m")
    }
}

// MARK: - Main Execution

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty || args.contains("-h") || args.contains("--help") {
    printHelp()
    exit(0)
}

if args.contains("-v") || args.contains("--version") {
    print("awake version \(version)")
    exit(0)
}

if args.first == "status" {
    showStatus()
    exit(0)
}

if args.contains("--on") {
    postDistributedNotification(name: "com.awake.mac.cli.start")
    print("\u{001B}[32m⚡️ Awake app session started.\u{001B}[0m")
    exit(0)
}

if args.contains("--off") {
    postDistributedNotification(name: "com.awake.mac.cli.stop")
    print("\u{001B}[33m💤 Awake app session stopped.\u{001B}[0m")
    exit(0)
}

// Parse flags vs wrapped command
var preventDisplay = false
var duration: TimeInterval? = nil
var remainingArgs: [String] = []

var i = 0
while i < args.count {
    let arg = args[i]
    if arg == "-d" || arg == "--display" {
        preventDisplay = true
        i += 1
    } else if arg == "-t" || arg == "--time" {
        if i + 1 < args.count {
            duration = parseDuration(args[i + 1])
            i += 2
        } else {
            print("\u{001B}[31mError: -t requires a duration (e.g. -t 30m)\u{001B}[0m")
            exit(1)
        }
    } else {
        remainingArgs.append(contentsOf: args[i...])
        break
    }
}

// Setup Clean Exit on Signals (SIGINT / SIGTERM)
let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSource.setEventHandler {
    print("\n\u{001B}[33mAwake: Interrupted. Restoring system sleep defaults...\u{001B}[0m")
    releaseAssertion()
    exit(130)
}
signal(SIGINT, SIG_IGN)
sigintSource.resume()

let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigtermSource.setEventHandler {
    releaseAssertion()
    exit(143)
}
signal(SIGTERM, SIG_IGN)
sigtermSource.resume()

// CASE 1: Command Wrapper Mode (e.g. `awake npm run build`)
if !remainingArgs.isEmpty {
    let cmd = remainingArgs.first!
    let cmdArgs = Array(remainingArgs.dropFirst())

    guard acquireAssertion(preventDisplaySleep: preventDisplay, reason: "awake wrapper: \(remainingArgs.joined(separator: " "))") else {
        print("\u{001B}[31mError: Could not acquire power assertion.\u{001B}[0m")
        exit(1)
    }

    print("\u{001B}[1m\u{001B}[33m⚡️ Awake:\u{001B}[0m Keeping Mac awake while executing: \u{001B}[1m\(remainingArgs.joined(separator: " "))\u{001B}[0m")
    if preventDisplay {
        print("   \u{001B}[90m(Display sleep also prevented)\u{001B}[0m")
    }

    let process = Process()
    // Find executable via /usr/bin/which or env
    let whichProcess = Process()
    whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    whichProcess.arguments = [cmd]
    let whichPipe = Pipe()
    whichProcess.standardOutput = whichPipe
    try? whichProcess.run()
    whichProcess.waitUntilExit()

    let whichPath = String(data: whichPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

    if let path = whichPath, !path.isEmpty {
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = cmdArgs
    } else {
        // Fallback to /bin/zsh -c
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", remainingArgs.joined(separator: " ")]
    }

    do {
        try process.run()
        process.waitUntilExit()
        releaseAssertion()
        let exitCode = process.terminationStatus
        if exitCode == 0 {
            print("\u{001B}[32m✅ Awake: Command completed successfully. Restored power rules.\u{001B}[0m")
        } else {
            print("\u{001B}[33m⚠️  Awake: Command exited with code \(exitCode). Restored power rules.\u{001B}[0m")
        }
        exit(exitCode)
    } catch {
        releaseAssertion()
        print("\u{001B}[31mError running command: \(error.localizedDescription)\u{001B}[0m")
        exit(1)
    }
}

// CASE 2: Duration Timer Mode (e.g. `awake -t 30m`)
if let dur = duration {
    guard acquireAssertion(preventDisplaySleep: preventDisplay, reason: "awake cli timer (\(formatDuration(dur)))") else {
        print("\u{001B}[31mError: Could not acquire power assertion.\u{001B}[0m")
        exit(1)
    }

    print("\u{001B}[1m\u{001B}[33m⚡️ Awake:\u{001B}[0m Keeping Mac awake for \u{001B}[1m\(formatDuration(dur))\u{001B}[0m...")
    if preventDisplay {
        print("   \u{001B}[90m(Display sleep prevented)\u{001B}[0m")
    }
    print("   Press \u{001B}[1mCtrl+C\u{001B}[0m to cancel at any time.\n")

    var remaining = dur
    let timer = DispatchSource.makeTimerSource(queue: .main)
    timer.schedule(deadline: .now(), repeating: 1.0)
    timer.setEventHandler {
        if remaining <= 0 {
            print("\r\u{001B}[K\u{001B}[32m✅ Awake: Session completed. Restoring system sleep defaults.\u{001B}[0m")
            releaseAssertion()
            exit(0)
        } else {
            print("\r\u{001B}[K⏳ Remaining: \u{001B}[1m\(formatDuration(remaining))\u{001B}[0m", terminator: "")
            fflush(stdout)
            remaining -= 1
        }
    }
    timer.resume()
    dispatchMain()
}

// CASE 3: Standalone Indefinite Mode (e.g. `awake` or `awake -d`)
guard acquireAssertion(preventDisplaySleep: preventDisplay, reason: "awake cli indefinite") else {
    print("\u{001B}[31mError: Could not acquire power assertion.\u{001B}[0m")
    exit(1)
}

print("\u{001B}[1m\u{001B}[33m⚡️ Awake:\u{001B}[0m Keeping Mac awake indefinitely.")
if preventDisplay {
    print("   \u{001B}[90m(Display sleep prevented)\u{001B}[0m")
}
print("   Press \u{001B}[1mCtrl+C\u{001B}[0m to exit.\n")

dispatchMain()
