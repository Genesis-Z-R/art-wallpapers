import SwiftUI
import AppKit

@MainActor
public final class DesktopPlaqueController {
    public static let shared = DesktopPlaqueController()

    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    public func showPlaque(for item: WallpaperItem, settings: PlaqueSettings) {
        guard settings.isEnabled else {
            hidePlaque()
            return
        }

        dismissTask?.cancel()

        let contentView = DesktopPlaqueView(item: item, settings: settings)
        let hostingController = NSHostingController(rootView: contentView)

        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 80),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.ignoresMouseEvents = true
            self.panel = newPanel
        }

        guard let panel = self.panel else { return }
        panel.contentViewController = hostingController

        // Configure as a desktop widget pinned to main desktop or floating panel
        if settings.stayOnMainDesktopOnly {
            panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            panel.collectionBehavior = [.stationary, .ignoresCycle]
        } else {
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }

        // Calculate plaque dimensions and position
        let targetSize = hostingController.view.fittingSize
        panel.setContentSize(targetSize)

        let screen = NSScreen.main ?? NSScreen.screens.first
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let margin: CGFloat = 28
        var originX: CGFloat = 0
        var originY: CGFloat = 0

        switch settings.position {
        case .bottomRight:
            originX = visibleFrame.maxX - targetSize.width - margin
            originY = visibleFrame.minY + margin
        case .bottomLeft:
            originX = visibleFrame.minX + margin
            originY = visibleFrame.minY + margin
        case .topRight:
            originX = visibleFrame.maxX - targetSize.width - margin
            originY = visibleFrame.maxY - targetSize.height - margin
        case .topLeft:
            originX = visibleFrame.minX + margin
            originY = visibleFrame.maxY - targetSize.height - margin
        }

        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            panel.animator().alphaValue = 1.0
        }

        // Auto-dismiss if not permanent
        if !settings.duration.isPermanent {
            let delaySeconds = settings.duration.seconds
            dismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.fadeOut()
            }
        }
    }

    public func fadeOut() {
        guard let panel = self.panel else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    public func hidePlaque() {
        dismissTask?.cancel()
        panel?.orderOut(nil)
    }
}
