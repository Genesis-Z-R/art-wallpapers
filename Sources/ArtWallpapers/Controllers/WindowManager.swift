import SwiftUI
import AppKit

@MainActor
public final class WindowManager {
    public static let shared = WindowManager()

    private var settingsWindowController: NSWindowController?
    private var collectionWindowController: NSWindowController?

    private init() {}

    public func showSettings() {
        if let existing = settingsWindowController?.window {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let contentView = SettingsView(manager: WallpaperManager.shared)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Art Wallpapers"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func showCollection() {
        if let existing = collectionWindowController?.window {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let contentView = CollectionBrowserView(manager: WallpaperManager.shared)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Art Wallpapers Collection"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.collectionWindowController = controller

        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
