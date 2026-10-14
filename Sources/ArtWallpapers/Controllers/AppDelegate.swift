import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app: lives in the menu bar, no dock icon
        NSApplication.shared.setActivationPolicy(.accessory)
        WallpaperManager.shared.start()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Stay running in menu bar
    }
}
