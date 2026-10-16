# Awake Feature Roadmap & Development Tracker

A comprehensive roadmap tracking proposed and in-progress features for the **Awake** macOS keep-awake utility.

---

## 📌 Status Legend
- [ ] ⏳ **Planned / Backlog**
- [x] 🚀 **Completed & Shipped**
- [ ] 🚧 **In Progress**

---

## 1. 🚀 App-Based Triggers (Process Automation)
Automatically activate keep-awake when resource-heavy or long-running applications are active.
- [x] **Running App Watcher**: UI in Settings (`App Triggers` tab) allowing users to choose installed applications via native `NSOpenPanel` (e.g. *Xcode, Blender, Final Cut Pro, Zoom, Handbrake, Terminal*).
- [x] **Background Process Observer**: Monitor `NSWorkspace.didLaunchApplicationNotification` and `NSWorkspace.didTerminateApplicationNotification` to auto-engage Awake without manual intervention.
- [x] **Auto-Stop on Termination**: Automatically stop keep-awake and restore normal energy-saver rules when watched applications quit.
- [x] **Active Trigger HUD Pill**: Distinct visual badge and info readout in the main popover HUD indicating the session was started by a watched app.

---

## 2. ⚡️ Instant Quick-Actions & Option-Click
Reduce interaction friction with immediate toggles.
- [x] **Option-Click Status Bar Icon**: Holding `Option (⌥)` while clicking the Awake menu bar item instantly toggles indefinite keep-awake without opening the popover.
- [x] **Global Keyboard Shortcut**: System-wide Carbon hotkey `⌥ ⌘ A` to toggle Awake from any application or workspace without requiring accessibility permissions.
- [x] **Menu Bar Double-Click Action**: Quick double-click on the status bar icon instantly starts or stops keep-awake with the last used timer session.
- [x] **Quick-Action Guide & Shortcut Settings**: Settings -> General tab now includes a dedicated shortcut toggle and monospaced gesture reference cheat-sheet.

---

## 3. 🎬 "Meeting & Presentation" Mode
Designed for professional screen-sharing, presentations, and webinars.
- [x] **Dedicated Presentation Preset**: One-click quick-switch action from both the main popover and the right-click menu bar menu that activates display keep-awake, locks screen awake, and transitions the app into a sleek purple Presentation HUD.
- [x] **Hide Desktop Icons**: Automatically hides all desktop files and icons via macOS Finder defaults (`defaults write com.apple.finder CreateDesktop false`) so screen shares and external displays remain clean; fully restores desktop state upon ending the presentation or quitting the app.
- [x] **Do Not Disturb (Focus) Integration**: Integrates with the macOS Shortcuts CLI (`shortcuts run "Toggle DND"`) to automate Focus / Do Not Disturb muting when presentations start and unmute when sessions end.
- [x] **Dedicated Presentation Tab in Settings**: Added settings tab with desktop cleanliness test button, custom Shortcuts name configuration, and direct link to the Shortcuts app.

---

## 4. 💻 Developer CLI (`awake` command)
CLI utility to keep your Mac awake during long terminal scripts, builds, or exports.
- [x] **Embedded Helper Binary**: Standalone, sub-second native Swift CLI compiled and embedded directly inside `Awake.app/Contents/Resources/awake` and bundled in the release DMG.
- [x] **Command Wrapper Syntax**: Seamless command execution wrapper keeping Mac awake until the child process completes (`awake npm run build`, `awake docker compose up`, `awake make test`) forwarding stdin/stdout/stderr and signals (SIGINT/SIGTERM).
- [x] **Flag-Based Controls**:
  - `awake -t 30m`: Duration keep-awake timer with live terminal countdown.
  - `awake -d`: Prevents display sleep alongside system sleep.
  - `awake --on` & `awake --off`: Zero-latency inter-process communication with the Awake GUI menu bar app via macOS Distributed Notifications.
  - `awake status`: Real-time inspection of Awake app state and system IOKit power assertions.
- [x] **One-Click Symlink Installer in Settings**: Dedicated "CLI" tab in Settings with 1-click install/uninstall to `~/.local/bin/awake`, live installation verification, and copy-ready terminal command cheat sheets.

---

## 5. 🔌 Display & Network Triggers
Hardware and peripheral awareness.
- [x] **External Display Trigger**: Listen for `NSApplication.didChangeScreenParametersNotification` and `CGDisplayIsBuiltin` to automatically engage Awake when plugged into an external monitor or projector, and safely release when unplugged.
- [x] **Active Network Download Guard**: Read BSD socket network throughput via `getifaddrs` every 2 seconds with zero external dependencies; prevents sleep as long as bandwidth exceeds a chosen threshold (e.g. `≥ 1 MB/s`), with customizable cooldown grace period before restoring power defaults.
- [x] **Unified Triggers Settings Tab**: Integrated into an intuitive segmented `Triggers` tab containing `Apps`, `Display`, and `Network` controls, live monitor detection status, and real-time network throughput speedometer.

---

## 6. 🛡️ Advanced Clamshell Safety (Thermal Protection)
Protect your MacBook from overheating while operating in closed-lid mode.
- [x] **SMC / IOHID Thermal Sensor Reading**: Dynamically queries Apple Silicon & Intel thermal hardware sensors via `IOHIDEventSystemClient` with fallback to `ProcessInfo.thermalState` without requiring root permissions.
- [x] **Thermal Throttling Failsafe**: Automatically detects when SoC temperature exceeds safety limits (default: 85°C or `.critical` thermal pressure); immediately drops sleep assertions and pauses closed-lid override to prevent overheating.
- [x] **Cooldown Recovery & Alert Notifications**: Emits warning audio chimes (`Basso`), dispatches system notifications on overheat, and automatically restores keep-awake once the system cools down past the resume threshold (72°C).
- [x] **Clamshell HUD & Settings Controls**: Added real-time temperature badge with live sensor readouts in `ClosedLidCard`, session overheat alert banner, and customizable cutoff/resume temperature pickers in Settings.

---

## 7. 🪄 Shortcuts & Raycast / Alfred Integration
Allow users and power-user launchers to control Awake via scriptable APIs.
- [x] **macOS App Intents (`AppShortcutsProvider`)**: Implemented native `StartAwakeIntent` (with duration, display keep-awake, and indefinite parameters), `StopAwakeIntent`, `ToggleAwakeIntent`, `ToggleClamshellIntent`, and `TogglePresentationIntent` with `appintentsmetadataprocessor` metadata extraction.
- [x] **Siri Voice Controls**: Registered `AppShortcutsProvider` with native Siri voice phrases (*"Hey Siri, start Awake"*, *"Hey Siri, keep my Mac awake with Awake"*, *"Hey Siri, stop Awake"*, *"Hey Siri, toggle Awake presentation mode"*).
- [x] **URL Scheme Handler (`awake://`)**: Full custom URL scheme handler supporting `awake://start?duration=30m&display=true`, `awake://stop`, `awake://toggle`, `awake://presentation`, `awake://clamshell`, and `awake://settings`.
- [x] **Raycast & Alfred Integration & Settings Hub**: Added an "Integrations" tab in Settings with copyable Raycast script commands, Alfred URL actions, and an interactive URL testing row.

---

## 8. 🎨 Customization & Appearance
Personalize the macOS status bar experience and auditory sensory feedback.
- [x] **Custom Menu Bar Icons**: Choose from 6 menu bar glyph styles (`Coffee Cup`, `Awake Eye`, `Night Owl`, `Flame`, `Lightning Bolt`, `Sun`) dynamically rendered with both idle outline and active filled states, live cache invalidation, and real-time menu bar updating.
- [x] **Aesthetic Sound Packs**: Selectable subtle acoustic sounds (`Subtle Clicks` [Tink & Pop], `Modern Chimes` [Hero & Funk], `Crystal Glass` [Glass & Bottle], `Soft Bells` [Ping & Pop], `Muted / Silent`) played via native `NSSound` upon session start, stop, timer completion, and safety alerts.
- [x] **Status Bar Countdown Styles**: 3 selectable formats for remaining session time in the macOS status bar (`Standard 00:25:00`, `Compact 25m / 1.5h`, `Progress Pie Glyph ● ◔ 25m`) dynamically updated every second.
- [x] **Dedicated Appearance Tab in Settings**: Rich configuration panel featuring visual icon selection cards, live countdown badge preview capsule, sound pack picker with interactive audition buttons, and instant preview feedback.

---

*Last Updated: 2026-10-16*
