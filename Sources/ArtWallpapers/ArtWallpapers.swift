import SwiftUI

@main
struct ArtWallpapersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = WallpaperManager.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverView(
                manager: manager,
                onOpenSettings: {
                    WindowManager.shared.showSettings()
                },
                onOpenCollection: {
                    WindowManager.shared.showCollection()
                }
            )
        } label: {
            if let icon = menuBarIcon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "photo.artframe")
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: NSImage? {
        let bundle = Bundle.main
        let possibleURLs = [
            bundle.url(forResource: "MenuBarIcon@2x", withExtension: "png"),
            bundle.url(forResource: "MenuBarIcon", withExtension: "png"),
            bundle.url(forResource: "MenuBarIconOriginal", withExtension: "png")
        ]
        for url in possibleURLs {
            if let validURL = url, let img = NSImage(contentsOf: validURL) {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                return img
            }
        }
        let devPaths = [
            "Resources/MenuBarIcon@2x.png",
            "Resources/MenuBarIcon.png"
        ]
        for path in devPaths {
            if let img = NSImage(contentsOfFile: path) {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                return img
            }
        }
        return nil
    }
}
