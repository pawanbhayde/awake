# Awake ☕️

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: macOS 14+](https://img.shields.io/badge/Platform-macOS%2014%20Sonoma%2B-black.svg?logo=apple)](https://apple.com/macos)
[![Architecture: Universal](https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%26%20Intel)-orange.svg)](https://github.com/pawanbhayde/awake)
[![Swift: 6.0](https://img.shields.io/badge/Swift-6.0%20%7C%205.9-F05138.svg?logo=swift)](https://swift.org)
[![Privacy: 100% Offline](https://img.shields.io/badge/Privacy-100%25%20Offline%20(Zero%20Tracking)-success.svg)](https://github.com/pawanbhayde/awake)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> **The modern, 100% free, and open-source keep-awake app for macOS.**
> Keep your Mac running long AI model tasks, code builds, uploads, and media renders, even with the lid closed. No paywalls, no subscriptions, zero tracking.

---

## ✨ Features

- **🕒 Versatile Keep-Awake Modes**:
  - **Quick Presets**: 15m, 30m, 1h, 2h, 4h, 8h with a single click.
  - **Custom Duration Slider**: Smoothly dial in exact minutes and hours up to 24 hours.
  - **Until Specific Time**: Set a target time (e.g. 5:30 PM) using native macOS date/time pickers.
  - **Indefinite (Unlimited)**: Keep awake until manually turned off.
  - **+15 Minutes Quick Extend**: Extend active sessions anytime without restarting.

- **💻 Clamshell / Closed-Lid Mode**:
  - Keep your Mac compiling, rendering, and processing AI agent tasks even when the MacBook lid is closed, without requiring external monitors.
  - **Watchdog Failsafe**: Normal sleep behavior is automatically restored when the timer ends, the app terminates, or a safeguard triggers.

- **🔋 Battery & Power Safeguards**:
  - **Low Battery Cutoff**: Automatically halts keep-awake sessions if battery drops below a configurable threshold (5% to 50%, default 20%).
  - **Require Power Adapter**: Restricts sessions to AC power, instantly ending sessions if the charger is disconnected.
  - **Desktop Mac Intelligence**: Gracefully detects iMacs, Mac minis, and Mac Studios without internal battery constraints.

- **🖥️ Display Sleep Decoupling**:
  - Choose whether the screen stays illuminated or is allowed to sleep to conserve energy and OLED/mini-LED lifespan while keeping background CPUs and networks running at full speed.

- **⚡️ Companion CLI (`awake-cli`)**:
  - Full terminal control: `awake start 2h --clamshell`, `awake stop`, `awake status`, and `awake toggle`.
  - Built into the application bundle with one-click terminal path installation (`/usr/local/bin/awake`).

- **🔔 Native macOS Experience**:
  - Dynamic menu bar icon with real-time green active status indicator.
  - Optional live countdown text in the macOS menu bar.
  - Native macOS user notifications on session start, completion, and safeguard events.
  - Subtle audio feedback cues.
  - Launch at Login support via macOS 14 `SMAppService`.

- **🛡️ 100% Free & Private**:
  - No subscriptions or license keys.
  - No telemetry, analytics, or third-party SDKs.
  - Zero network permissions required: completely offline.

---

## 🆚 Feature Comparison

| Feature | **Awake** | **WakeBee** | **Amphetamine** |
| :--- | :---: | :---: | :---: |
| **Price** | **100% Free (Open Source)** | $12/yr or $29 Lifetime | Free (Closed Source) |
| **License Verification / Paywall** | **None (Zero)** | Required | None |
| **Clamshell / Closed-Lid Mode** | **Yes (Built-in Helper Setup)** | Yes | Requires external companion app |
| **Watchdog Sleep Restore Failsafe** | **Yes** | Yes | Yes |
| **Battery Cutoff Threshold** | **Yes (5% to 50% customizable)** | Yes | Yes |
| **Require AC Adapter Rule** | **Yes** | Yes | Yes |
| **Display Sleep vs System Sleep Decoupling** | **Yes** | Yes | Yes |
| **Menu Bar Real-Time Countdown** | **Yes** | Yes | Yes |
| **Launch at Login (macOS 14+ `SMAppService`)** | **Yes** | Yes | Legacy login items |
| **Companion CLI Automation** | **Yes (`awake start`, `status`)** | No | Legacy AppleScript only |
| **Modern SwiftUI Menu Bar HUD** | **Yes** | Yes | Cocoa / Objective-C legacy |
| **Zero Telemetry / Privacy First** | **100% Offline** | Analytics included | Analytics included |

---

## 🚀 Installation & Getting Started

### Option 1: Download the Release DMG (Recommended)

1. Download the latest `Awake.dmg` from [GitHub Releases](https://github.com/pawanbhayde/awake/releases).
2. Open the disk image and drag **Awake.app** into your `/Applications` folder.
3. Launch Awake from Applications or Spotlight. It will live cleanly in your menu bar.

### Option 2: Build from Source

```bash
git clone https://github.com/pawanbhayde/awake.git
cd awake
chmod +x scripts/build_dmg.sh
./scripts/build_dmg.sh
```
The output disk image will be generated at `dist/Awake.dmg`.

### Option 3: Open in Xcode

1. Open `awake.xcodeproj` in Xcode 15 or 16.
2. Select the `awake` scheme and destination `My Mac`.
3. Press `Cmd + R` to run or `Cmd + B` to build.

---

## ⚡️ Command Line Interface (`awake`)

Awake includes a first-class CLI tool to script and automate keep-awake sessions in shell workflows, cron jobs, and CI/build scripts:

```bash
# Start keep-awake for 2 hours with closed-lid clamshell support
awake start 2h --clamshell

# Start keep-awake for 45 minutes with display kept awake
awake start 45m --keep-display

# Check current session state, time remaining, and battery level
awake status

# Extend the active session by 15 minutes
awake extend 15m

# Stop active session and immediately restore normal macOS sleep
awake stop
```

You can install the CLI directly into your system PATH from the Awake Settings menu, or symlink it:
```bash
sudo ln -sf /Applications/Awake.app/Contents/Resources/awake /usr/local/bin/awake
```

---

## 🛠️ Architecture

- **`awake/Core/AssertionManager.swift`**: Directly interfaces with Apple's `IOKit.pwr_mgt` kernel API (`kIOPMAssertionTypePreventUserIdleSystemSleep` and `kIOPMAssertionTypePreventUserIdleDisplaySleep`) for zero-overhead, battery-efficient system assertions.
- **`awake/Core/PowerMonitor.swift`**: Listens to system power dispatch events via `IOPSNotificationCreateRunLoopSource` and `IOKit.ps` to monitor battery levels, charging status, and AC connection changes in real time.
- **`awake/Core/ClosedLidManager.swift`**: Safely manages macOS clamshell sleep prevention via passwordless `pmset -a disablesleep` rules in `/etc/sudoers.d/awake_pmset`, with failsafe restoration on application exit.
- **`awake/Core/AppTriggerManager.swift`**: Monitors running application processes to automatically initiate keep-awake sessions when specified apps (e.g. Xcode, Final Cut Pro, Blender, Docker) are active.
- **`awake/Core/ThermalProtectionManager.swift`**: Automatically releases assertions if CPU/GPU temperatures reach dangerous thermal levels.
- **`awake/App/MenuBarController.swift`**: Hosts the `NSStatusItem` in the system menu bar, manages popover display and click monitoring, and draws dynamic status badges.
- **`awake-cli/main.swift`**: Command-line binary communicating via Darwin notifications and URL schemes (`awake://`).

---

## 🤝 Contributing

Contributions are what make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated!

Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting pull requests or issues.

---

## 🔒 Security

For security vulnerability reporting, please see our [Security Policy](SECURITY.md).

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more details. Free to use, modify, and distribute for personal and commercial purposes.
