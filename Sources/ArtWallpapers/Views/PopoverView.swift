import SwiftUI
import AppKit

@MainActor
public struct PopoverView: View {
    @ObservedObject var manager: WallpaperManager
    let onOpenSettings: () -> Void
    let onOpenCollection: () -> Void

    @MainActor
    public init(
        manager: WallpaperManager,
        onOpenSettings: @escaping () -> Void,
        onOpenCollection: @escaping () -> Void
    ) {
        self.manager = manager
        self.onOpenSettings = onOpenSettings
        self.onOpenCollection = onOpenCollection
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .frame(width: 26, height: 26)

                    if let headerIcon = headerAppIcon {
                        Image(nsImage: headerIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    } else {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Art Wallpapers")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusDotColor)
                            .frame(width: 6, height: 6)

                        Text(manager.statusText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Current Artwork Preview
            ArtworkCardView(
                item: manager.currentWallpaper,
                storagePath: manager.settings.storageLocationPath,
                isUpdating: manager.isUpdating,
                onFavoriteTap: {
                    if let item = manager.currentWallpaper {
                        manager.toggleFavorite(item: item)
                    }
                },
                onChevronTap: {
                    if let url = manager.currentWallpaper?.webUrl {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
            .id(manager.currentWallpaper?.id)
            .padding(.horizontal, 14)

            // Optional Error Banner
            if let error = manager.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.primary.opacity(0.9))
                        .lineLimit(2)
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.12)))
                .padding(.horizontal, 14)
            }

            // Action Items
            VStack(spacing: 2) {
                MenuActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Next Wallpaper Now",
                    shortcut: manager.settings.enableGlobalHotkey ? "⌃⌥⌘W" : nil,
                    isDisabled: manager.isUpdating
                ) {
                    manager.nextWallpaperNow()
                }

                MenuActionButton(
                    icon: "photo.on.rectangle.angled",
                    title: "Browse Collection",
                    shortcut: nil
                ) {
                    onOpenCollection()
                }

                MenuActionButton(
                    icon: "gearshape",
                    title: "Settings",
                    shortcut: nil
                ) {
                    onOpenSettings()
                }

                Divider()
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)

                MenuActionButton(
                    icon: manager.isPaused ? "play.fill" : "pause.fill",
                    title: manager.isPaused ? "Resume" : "Pause",
                    shortcut: nil
                ) {
                    manager.togglePause()
                }

                MenuActionButton(
                    icon: "power",
                    title: "Quit",
                    shortcut: nil
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }

    private var statusDotColor: Color {
        if manager.isUpdating {
            return .blue
        }
        if manager.isPaused {
            return .orange
        }
        if manager.errorMessage != nil {
            return .yellow
        }
        return .green
    }

    private var headerAppIcon: NSImage? {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: "AppIconOriginal", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let img = NSImage(contentsOfFile: "Resources/AppIconOriginal.png") {
            return img
        }
        return NSApp.applicationIconImage
    }
}

// MARK: - Action Button

private struct MenuActionButton: View {
    let icon: String
    let title: String
    let shortcut: String?
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundColor(.primary.opacity(0.85))

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Spacer()

                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

private struct MenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04))
            )
    }
}

// MARK: - Visual Effect View for Native macOS Translucency

public struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
