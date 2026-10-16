import Foundation
import AppKit
import Carbon
import Combine

@MainActor
public final class GlobalHotkeyManager: ObservableObject {
    public static let shared = GlobalHotkeyManager()

    private let userDefaultsKey = "globalHotkeyEnabled"

    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: userDefaultsKey)
            if isEnabled {
                registerHotkey()
            } else {
                unregisterHotkey()
            }
        }
    }

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {
        if UserDefaults.standard.object(forKey: userDefaultsKey) == nil {
            self.isEnabled = true
        } else {
            self.isEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        }

        if isEnabled {
            registerHotkey()
        }
    }

    public func registerHotkey() {
        unregisterHotkey()

        let hotKeyID = EventHotKeyID(signature: OSType(0x41574B45), id: 1) // 'AWKE', id: 1
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
            Task { @MainActor in
                GlobalHotkeyManager.shared.handleHotkeyTriggered()
            }
            return noErr
        }

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard installStatus == noErr else {
            print("Failed to install Carbon event handler: \(installStatus)")
            return
        }

        // Register ⌥ ⌘ A (Option + Command + A)
        let keyCode = UInt32(kVK_ANSI_A)
        let modifiers = UInt32(cmdKey | optionKey)

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            print("Failed to register global hotkey ⌥⌘A: \(registerStatus)")
        }
    }

    public func unregisterHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    public func handleHotkeyTriggered() {
        if AppState.shared.status.isRunning {
            AppState.shared.stopSession()
        } else {
            AppState.shared.selectedMode = .unlimited
            AppState.shared.startSession()
        }
    }
}
