import Foundation
import IOKit.pwr_mgt

@MainActor
public final class AssertionManager {
    public static let shared = AssertionManager()

    private var systemSleepAssertionID: IOPMAssertionID = 0
    private var displaySleepAssertionID: IOPMAssertionID = 0

    public var isSystemSleepPrevented: Bool {
        systemSleepAssertionID != 0
    }

    public var isDisplaySleepPrevented: Bool {
        displaySleepAssertionID != 0
    }

    private init() {}

    /// Activates power assertions to prevent macOS from sleeping
    /// - Parameter preventDisplaySleep: When true, prevents display sleep as well as system sleep. When false, allows display to turn off while keeping CPU & network active.
    public func activate(preventDisplaySleep: Bool) {
        // 1. Prevent System Idle Sleep (keeps CPU, networking, background tasks running)
        if systemSleepAssertionID == 0 {
            let reason = "Awake: Keeping system awake for background tasks" as CFString
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &systemSleepAssertionID
            )
            if result != kIOReturnSuccess {
                print("Failed to create system sleep assertion: \(result)")
                systemSleepAssertionID = 0
            }
        }

        // 2. Prevent Display Sleep if requested
        updateDisplaySleep(preventDisplaySleep: preventDisplaySleep)
    }

    /// Dynamically updates the display sleep assertion without interrupting the system sleep assertion
    public func updateDisplaySleep(preventDisplaySleep: Bool) {
        if preventDisplaySleep {
            if displaySleepAssertionID == 0 {
                let reason = "Awake: Keeping display awake" as CFString
                let result = IOPMAssertionCreateWithName(
                    kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                    reason,
                    &displaySleepAssertionID
                )
                if result != kIOReturnSuccess {
                    print("Failed to create display sleep assertion: \(result)")
                    displaySleepAssertionID = 0
                }
            }
        } else {
            if displaySleepAssertionID != 0 {
                IOPMAssertionRelease(displaySleepAssertionID)
                displaySleepAssertionID = 0
            }
        }
    }

    /// Releases all active power assertions and returns power management to macOS defaults
    public func deactivate() {
        if displaySleepAssertionID != 0 {
            IOPMAssertionRelease(displaySleepAssertionID)
            displaySleepAssertionID = 0
        }

        if systemSleepAssertionID != 0 {
            IOPMAssertionRelease(systemSleepAssertionID)
            systemSleepAssertionID = 0
        }
    }

    deinit {
        if displaySleepAssertionID != 0 {
            IOPMAssertionRelease(displaySleepAssertionID)
        }
        if systemSleepAssertionID != 0 {
            IOPMAssertionRelease(systemSleepAssertionID)
        }
    }
}
