import Foundation
import AppKit

public final class DesktopService: Sendable {
    public static let shared = DesktopService()

    private init() {}

    /// Applies the image at localFileURL to connected display(s)
    @MainActor
    public func setDesktopWallpaper(fileURL: URL, fit: ImageFitOption, for targetScreen: NSScreen? = nil) throws {
        var options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .allowClipping: true
        ]

        switch fit {
        case .fillScreen:
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            options[.allowClipping] = true
        case .fitToScreen:
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            options[.allowClipping] = false
        case .stretchToFill:
            options[.imageScaling] = NSImageScaling.scaleAxesIndependently.rawValue
        case .center:
            options[.imageScaling] = NSImageScaling.scaleNone.rawValue
        }

        let screensToApply = targetScreen != nil ? [targetScreen!] : NSScreen.screens
        var workspaceSuccess = false

        for screen in screensToApply {
            do {
                try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: options)
                workspaceSuccess = true
            } catch {
                // Will try AppleScript fallback below
            }
        }

        if !workspaceSuccess {
            // AppleScript fallback
            let escapedPath = fileURL.path.replacingOccurrences(of: "\"", with: "\\\"")
            let scriptSource = """
            tell application "System Events"
                tell every desktop
                    set picture to POSIX file "\(escapedPath)"
                end tell
            end tell
            """

            var errorInfo: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                script.executeAndReturnError(&errorInfo)
                if let errorInfo = errorInfo {
                    throw NSError(
                        domain: "DesktopService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "AppleScript wallpaper error: \(errorInfo)"]
                    )
                }
            }
        }
    }
}
