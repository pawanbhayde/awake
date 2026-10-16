# Awake ☕️

> **The modern, 100% free, and open-source keep-awake app for macOS.**
> Keep your Mac running long AI model tasks, code builds, uploads, and media renders—even with the lid closed. No paywalls, no subscriptions, zero tracking.

---

## ✨ Features

- **🕒 Versatile Keep-Awake Modes**:
  - **Quick Presets**: 15m, 30m, 1h, 2h, 4h, 8h with a single click.
  - **Custom Duration Slider**: Smoothly dial in exact minutes and hours up to 24 hours.
  - **Until Specific Time**: Set a target time (e.g. 5:30 PM) using native macOS date/time pickers.
  - **Indefinite (Unlimited)**: Keep awake until manually turned off.
  - **+15 Minutes Quick Extend**: Extend active sessions anytime without restarting.

- **💻 Clamshell / Closed-Lid Mode**:
  - Keep your Mac compiling, rendering, and processing AI agent tasks even when the MacBook lid is closed—without requiring external monitors.
  - **Watchdog Failsafe**: Normal sleep behavior is automatically restored when the timer ends, the app terminates, or a safeguard triggers.

- **🔋 Battery & Power Safeguards**:
  - **Low Battery Cutoff**: Automatically halts keep-awake sessions if battery drops below a configurable threshold (5% – 50%, default 20%).
  - **Require Power Adapter**: Restricts sessions to AC power, instantly ending sessions if the charger is disconnected.
  - **Desktop Mac Intelligence**: Gracefully detects iMacs, Mac minis, and Mac Studios without internal battery constraints.

- **🖥️ Display Sleep Decoupling**:
  - Choose whether the screen stays illuminated or is allowed to sleep to conserve energy and OLED/mini-LED lifespan while keeping background CPUs and networks running at full speed.

- **🔔 Native macOS Experience**:
  - Dynamic menu bar icon with real-time green active status indicator.
  - Optional live countdown text in the macOS menu bar.
  - Native macOS user notifications on session start, completion, and safeguard events.
  - Subtle audio feedback cues.
  - Launch at Login support via `SMAppService`.

- **🛡️ 100% Free & Private**:
  - No subscriptions or license keys.
  - No telemetry, analytics, or third-party SDKs.
  - Zero network permissions required.

---

## 🆚 Feature Comparison

| Feature | **Awake** | **WakeBee** | **Amphetamine** |
| :--- | :---: | :---: | :---: |
| **Price** | **100% Free (Open Source)** | $12/yr or $29 Lifetime | Free (Closed Source) |
| **License Verification / Paywall** | **None (Zero)** | Required | None |
| **Clamshell / Closed-Lid Mode** | **Yes (Built-in Helper Setup)** | Yes | Requires external companion app |
| **Watchdog Sleep Restore Failsafe** | **Yes** | Yes | Yes |
| **Battery Cutoff Threshold** | **Yes (5%–50% customizable)** | Yes | Yes |
| **Require AC Adapter Rule** | **Yes** | Yes | Yes |
| **Display Sleep vs System Sleep Decoupling** | **Yes** | Yes | Yes |
| **Menu Bar Real-Time Countdown** | **Yes** | Yes | Yes |
| **Launch at Login (macOS 14+ `SMAppService`)** | **Yes** | Yes | Legacy login items |
| **Modern SwiftUI Menu Bar HUD** | **Yes** | Yes | Cocoa / Objective-C legacy |
| **Zero Telemetry / Privacy First** | **100% Offline** | Analytics included | Analytics included |

---

## 🚀 Installation & Building

### Option 1: Build the Release DMG

```bash
git clone https://github.com/pawanbhayde/awake.git
cd awake
chmod +x scripts/build_dmg.sh
./scripts/build_dmg.sh
```
The output disk image will be created at `dist/Awake.dmg`. Mount the DMG and drag **Awake.app** into `/Applications`.

### Option 2: Open in Xcode

1. Open `awake.xcodeproj` in Xcode 15 or 16.
2. Select the `awake` scheme and destination `My Mac`.
3. Press `Cmd + R` to run or `Cmd + B` to build.

---

## 🛠️ Architecture

- **`AssertionManager.swift`**: Directly interfaces with Apple's `IOKit.pwr_mgt` kernel API (`kIOPMAssertionTypePreventUserIdleSystemSleep` and `kIOPMAssertionTypePreventUserIdleDisplaySleep`) for zero-overhead, battery-efficient system assertions.
- **`PowerMonitor.swift`**: Listens to system power dispatch events via `IOPSNotificationCreateRunLoopSource` and `IOKit.ps` to monitor battery levels, charging status, and AC connection changes in real time.
- **`ClosedLidManager.swift`**: Safely manages macOS clamshell sleep prevention via passwordless `pmset -a disablesleep` rules in `/etc/sudoers.d/awake_pmset`, with failsafe restoration on application exit.
- **`NotificationManager.swift`**: Handles native `UserNotifications` delivery and system sound cues (`NSSound`).
- **`MenuBarController.swift`**: Hosts the `NSStatusItem` in the system menu bar, manages popover display and click monitoring, and draws dynamic status badges.

---

## 📄 License

MIT License. Free to use, modify, and distribute for personal and commercial purposes.
