import Cocoa
import SwiftUI

@MainActor
public final class MenuBarController: NSObject, NSPopoverDelegate {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var lastCloseTime: TimeInterval = 0

    // Callback hooked by SettingsBridgeView / PopoverView's @Environment(\.openSettings)
    public var swiftUIOpenSettings: (() -> Void)?
    private var settingsBridgeWindow: NSWindow?

    // Cached pre-rendered images for zero-overhead rendering
    private var cachedIdleImage: NSImage?
    private var cachedActiveImage: NSImage?

    private override init() {
        super.init()
    }

    public func setup() {
        // Initialize status item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.rightMouseUp])

        // Setup popover - snappy, instant appearance without window sliding lag
        popover = NSPopover()
        popover.contentSize = NSSize(width: 330, height: 465)
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self

        let hostingController = NSHostingController(rootView: PopoverView())
        popover.contentViewController = hostingController

        // Pre-warm the view hierarchy so the first open has zero cold-start lag
        _ = hostingController.view

        // Setup SwiftUI Settings Bridge to guarantee native OpenSettingsAction without AppKit showSettingsWindow warnings
        struct SettingsBridgeView: View {
            @Environment(\.openSettings) private var openSettingsAction
            var body: some View {
                Color.clear
                    .frame(width: 1, height: 1)
                    .onAppear {
                        MenuBarController.shared.swiftUIOpenSettings = {
                            openSettingsAction()
                        }
                    }
            }
        }
        let bridgeWin = NSWindow(contentRect: NSRect(x: -2000, y: -2000, width: 1, height: 1),
                                 styleMask: .borderless,
                                 backing: .buffered,
                                 defer: false)
        bridgeWin.isReleasedWhenClosed = false
        bridgeWin.contentView = NSHostingView(rootView: SettingsBridgeView())
        bridgeWin.orderFront(nil)
        self.settingsBridgeWindow = bridgeWin

        // Setup status change listener
        AppState.shared.onStatusChanged = { [weak self] _ in
            self?.updateStatusIcon()
        }

        updateStatusIcon()
    }

    // MARK: - Status Bar Icon & Menu Bar Title

    public func invalidateIconCache() {
        cachedIdleImage = nil
        cachedActiveImage = nil
    }

    public func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let isRunning = AppState.shared.status.isRunning

        if !isRunning {
            button.image = getIdleImage()
            button.title = ""
        } else {
            button.image = getActiveImage()
            updateRemainingTimeMenuBar()
        }
    }

    public func updateRemainingTimeMenuBar() {
        guard let button = statusItem.button else { return }
        if AppState.shared.showTimeInMenuBar && AppState.shared.status.isRunning {
            if AppState.shared.selectedMode == .unlimited {
                if button.title != " ∞" {
                    button.title = " ∞"
                }
                return
            }

            let formatted = " " + AppearanceManager.shared.formatRemainingTime(
                remaining: AppState.shared.remainingSeconds,
                total: AppState.shared.selectedDuration
            )
            if button.title != formatted {
                button.title = formatted
            }
        } else {
            if button.title != "" {
                button.title = ""
            }
        }
    }

    private func getIdleImage() -> NSImage {
        let style = AppearanceManager.shared.iconStyle
        if let cached = cachedIdleImage, cached.name() == style.rawValue {
            return cached
        }

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        var image = NSImage(systemSymbolName: style.idleSymbolName, accessibilityDescription: "Awake (Idle)")?
            .withSymbolConfiguration(symbolConfig)

        if image == nil {
            image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Awake (Idle)")?
                .withSymbolConfiguration(symbolConfig)
        }

        image?.isTemplate = true
        image?.setName(style.rawValue)
        cachedIdleImage = image
        return image ?? NSImage()
    }

    private func getActiveImage() -> NSImage {
        let style = AppearanceManager.shared.iconStyle
        let isPres = PresentationModeManager.shared.isPresentationActive
        let cacheKey = "\(style.rawValue)_\(isPres ? "pres" : "awake")"

        if let cached = cachedActiveImage, cached.name() == cacheKey {
            return cached
        }

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let symbolName = isPres ? "sparkles.tv" : style.activeSymbolName
        let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Awake (Active)")?
            .withSymbolConfiguration(symbolConfig)
            ?? NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Awake (Active)")?
                .withSymbolConfiguration(symbolConfig)
            ?? NSImage()

        let baseSize = baseImage.size
        let canvasWidth = baseSize.width + (isPres ? 0 : 8)
        let canvasHeight = max(baseSize.height, 18)
        let combinedImage = NSImage(size: NSSize(width: canvasWidth, height: canvasHeight))

        combinedImage.lockFocus()

        let baseRect = NSRect(
            x: 0,
            y: (canvasHeight - baseSize.height) / 2,
            width: baseSize.width,
            height: baseSize.height
        )

        baseImage.isTemplate = true
        baseImage.draw(in: baseRect)

        if !isPres {
            let dotRadius: CGFloat = 2.5
            let dotRect = NSRect(
                x: baseSize.width + 1.5,
                y: (canvasHeight / 2) - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let path = NSBezierPath(ovalIn: dotRect)
            NSColor.systemGreen.setFill()
            path.fill()
        }

        combinedImage.unlockFocus()
        combinedImage.isTemplate = false
        combinedImage.setName(cacheKey)

        cachedActiveImage = combinedImage
        return combinedImage
    }

    // MARK: - Actions & Interactions

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else {
            togglePopoverVisibility()
            return
        }

        if event.type == .rightMouseUp {
            closePopover(nil)
            showContextMenu()
        } else {
            togglePopoverVisibility()
        }
    }

    private func togglePopoverVisibility() {
        if popover.isShown {
            closePopover(nil)
        } else {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastCloseTime < 0.2 {
                return
            }
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    public func closePopover(_ sender: AnyObject?) {
        if popover.isShown {
            lastCloseTime = ProcessInfo.processInfo.systemUptime
            popover.performClose(sender)
        }
    }

    public func popoverDidClose(_ notification: Notification) {
        lastCloseTime = ProcessInfo.processInfo.systemUptime
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let statusText = AppState.shared.status.isRunning
            ? "Awake: Active (\(AppearanceManager.shared.formatRemainingTime(remaining: AppState.shared.remainingSeconds, total: AppState.shared.selectedDuration)))"
            : "Awake: Idle"

        let headerItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        if AppState.shared.status.isRunning {
            let stopItem = NSMenuItem(title: "Deactivate", action: #selector(contextStopAction), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)
        } else {
            let startItem = NSMenuItem(title: "Activate Indefinitely", action: #selector(contextStartIndefiniteAction), keyEquivalent: "")
            startItem.target = self
            menu.addItem(startItem)

            let start1HrItem = NSMenuItem(title: "Activate for 1 Hour", action: #selector(contextStart1HrAction), keyEquivalent: "")
            start1HrItem.target = self
            menu.addItem(start1HrItem)
        }

        menu.addItem(NSMenuItem.separator())

        let presentationItem = NSMenuItem(
            title: PresentationModeManager.shared.isPresentationActive ? "Exit Presentation Mode" : "Presentation Mode",
            action: #selector(contextTogglePresentationAction),
            keyEquivalent: "p"
        )
        presentationItem.keyEquivalentModifierMask = [.command, .shift]
        presentationItem.target = self
        menu.addItem(presentationItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Awake", action: #selector(quitAppAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func contextStopAction() {
        AppState.shared.stopSession()
    }

    @objc private func contextStartIndefiniteAction() {
        AppState.shared.selectedMode = .unlimited
        AppState.shared.startSession()
    }

    @objc private func contextStart1HrAction() {
        AppState.shared.selectedMode = .timer
        AppState.shared.selectedDuration = 3600
        AppState.shared.startSession()
    }

    @objc private func contextTogglePresentationAction() {
        PresentationModeManager.shared.togglePresentationMode()
    }

    @objc private func openSettingsAction() {
        openSettings()
    }

    @objc private func quitAppAction() {
        NSApplication.shared.terminate(nil)
    }

    public func openSettings() {
        closePopover(nil)
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApp.windows {
            if window.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" || window.title.contains("Settings") {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        if let swiftUIOpen = swiftUIOpenSettings {
            swiftUIOpen()
        }
    }
}
