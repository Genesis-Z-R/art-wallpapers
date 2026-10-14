import AppKit

public final class HotkeyService: @unchecked Sendable {
    public static let shared = HotkeyService()

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onTrigger: (@MainActor () -> Void)?

    private init() {}

    public func setup(onTrigger: @escaping @MainActor () -> Void) {
        self.onTrigger = onTrigger
    }

    public func setEnabled(_ enabled: Bool) {
        if enabled {
            startListening()
        } else {
            stopListening()
        }
    }

    private func startListening() {
        stopListening()

        // Key code for 'W' on macOS US keyboard is 13
        let keyCodeW: UInt16 = 13
        let targetFlags: NSEvent.ModifierFlags = [.control, .option, .command]

        // Global monitor (when app is in background)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection([.control, .option, .command, .shift])
            if flags == targetFlags && (event.keyCode == keyCodeW || event.charactersIgnoringModifiers?.lowercased() == "w") {
                Task { @MainActor [weak self] in
                    self?.onTrigger?()
                }
            }
        }

        // Local monitor (when app popover or window is active)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection([.control, .option, .command, .shift])
            if flags == targetFlags && (event.keyCode == keyCodeW || event.charactersIgnoringModifiers?.lowercased() == "w") {
                Task { @MainActor [weak self] in
                    self?.onTrigger?()
                }
                return nil // consume event
            }
            return event
        }
    }

    private func stopListening() {
        if let gm = globalMonitor {
            NSEvent.removeMonitor(gm)
            globalMonitor = nil
        }
        if let lm = localMonitor {
            NSEvent.removeMonitor(lm)
            localMonitor = nil
        }
    }
}
