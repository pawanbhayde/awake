# Contributing to Awake

First off, thank you for your interest in contributing to Awake! Awake is a 100% free, private, and open-source keep-awake utility built for macOS.

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Architecture Overview

Awake is composed of four primary parts:

1. **`awake/` (macOS Menu Bar App)**:
   - Written in modern Swift and SwiftUI with AppKit integration.
   - Communicates with Apple's `IOKit.pwr_mgt` kernel API (`AssertionManager.swift`) for zero-overhead system assertions.
   - Monitors battery and charger status via `IOPSNotificationCreateRunLoopSource` (`PowerMonitor.swift`).
   - Manages closed-lid clamshell sessions safely via passwordless `pmset` rules (`ClosedLidManager.swift`) with watchdog failsafes.
   - Provides global hotkeys, app triggers, display triggers, network guards, and thermal monitoring.
2. **`awake-cli/` (Companion CLI)**:
   - Standalone command-line binary (`awake start 2h --clamshell`, `awake status`, `awake stop`).
   - Communicates with the running app via custom URL schemes (`awake://`) and distributed notifications.
3. **`scripts/` (Build & Packaging)**:
   - `build_dmg.sh`: Compiles the app and CLI in Release mode and packages them into a clean, drag-and-drop DMG installer.
4. **`landing-page/` (Project Website)**:
   - Modern documentation and landing page built with Astro and Tailwind CSS.

---

## Development Prerequisites

- **Operating System**: macOS 14 Sonoma or later (macOS 15 Sequoia recommended).
- **IDE**: Xcode 15.0 or later (Xcode 16+ recommended).
- **Swift**: Swift 6 or Swift 5.9+.
- **Node.js & pnpm**: Node 18+ and pnpm (required only if modifying `landing-page/`).

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/pawanbhayde/awake.git
cd awake
```

### 2. Build and Run in Xcode

1. Open `awake.xcodeproj` in Xcode.
2. Select the `awake` scheme and destination `My Mac`.
3. Press `Cmd + R` to build and run, or `Cmd + B` to build.

### 3. Build the Release DMG via CLI

To compile both the app and the CLI binary and bundle them into `dist/Awake.dmg`:

```bash
chmod +x scripts/build_dmg.sh
./scripts/build_dmg.sh
```

### 4. Working on the Landing Page

```bash
cd landing-page
pnpm install
pnpm dev
```
Open `http://localhost:4321` in your browser. Verify production builds before submitting changes:
```bash
pnpm build
```

---

## Development Principles & Guidelines

When contributing code or copy to Awake, please keep these core tenets in mind:

1. **100% Offline and Zero Telemetry**:
   - Awake has zero tracking, zero analytics, zero ad SDKs, and zero network requests.
   - Do not introduce dependencies or APIs that transmit user telemetry or require outbound internet access.
2. **Battery & Hardware Safety First**:
   - Power assertions must release cleanly when timers expire, batteries drop below cutoff, or the app terminates.
   - Any clamshell mode changes (`pmset`) must always preserve the watchdog failsafe so sleep behavior is safely restored.
3. **Native Apple HIG Aesthetics**:
   - UI elements should feel right at home on modern macOS. Use native system colors, SF Symbols, and standard Apple typography.
4. **Content & Punctuation Hygiene**:
   - Do not use long hyphens (em-dashes `` or en-dashes ``) anywhere in user-facing content, documentation, or code comments. Use standard hyphens `-`, commas `,` or colons `:`.

---

## Submitting Pull Requests

1. **Fork the repository** on GitHub.
2. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. **Commit your changes**:
   - Keep commits focused and provide clear, descriptive commit messages.
   - Follow standard Git conventions (`feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`).
4. **Test thoroughly**:
   - Test power assertions, menu bar popover behavior, and settings persistence.
   - If modifying the CLI, verify commands (`start`, `stop`, `status`, `toggle`).
   - If modifying the landing page, run `pnpm build` to confirm zero errors.
5. **Open a Pull Request**:
   - Fill out the PR template with details about your change and testing steps.
   - Be receptive to feedback during the code review process.

---

## Reporting Issues

- **Bug Reports**: Open an issue using the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.yml). Include your macOS version, Mac hardware model (Apple Silicon vs Intel), reproduction steps, and expected behavior.
- **Feature Requests**: Open an issue using the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.yml) describing the problem, proposed solution, and alternative approaches considered.

Thank you for helping make Awake better for everyone!
