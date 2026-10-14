import SwiftUI
import AppKit

public struct ArtworkCardView: View {
    let item: WallpaperItem?
    let storagePath: String
    let isUpdating: Bool
    let onFavoriteTap: () -> Void
    let onChevronTap: () -> Void

    public init(
        item: WallpaperItem?,
        storagePath: String,
        isUpdating: Bool,
        onFavoriteTap: @escaping () -> Void = {},
        onChevronTap: @escaping () -> Void
    ) {
        self.item = item
        self.storagePath = storagePath
        self.isUpdating = isUpdating
        self.onFavoriteTap = onFavoriteTap
        self.onChevronTap = onChevronTap
    }

    private var currentImage: NSImage? {
        guard let item = item else { return nil }
        let dir = (storagePath as NSString).expandingTildeInPath
        let fileURL = URL(fileURLWithPath: dir).appendingPathComponent(item.localFileName)
        return ImageCache.shared.image(for: fileURL)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image Preview
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .aspectRatio(16/10, contentMode: .fit)

                if let currentImage {
                    Image(nsImage: currentImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else if isUpdating {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.9)
                        Text("Loading painting...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("No wallpaper selected yet")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                // Loading overlay while updating to the next wallpaper
                if isUpdating && currentImage != nil {
                    ZStack {
                        Color.black.opacity(0.35)
                        ProgressView()
                            .scaleEffect(1.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .frame(height: 180)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)

            // Artwork Details
            if let item {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(item.artist)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text(item.dateDisplay)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                    }

                    Spacer(minLength: 8)

                    // Action buttons
                    HStack(spacing: 6) {
                        Button(action: onFavoriteTap) {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(item.isFavorite ? .red : .secondary)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(item.isFavorite ? Color.red.opacity(0.15) : Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .help(item.isFavorite ? "Remove from Favorites" : "Add to Favorites")

                        Button(action: onChevronTap) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                        .help("View artwork details on \(item.museum.shortName)")
                    }
                }

                // Badges
                HStack(spacing: 6) {
                    Text(item.museum.shortName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )

                    ForEach(item.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.primary.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(nsColor: .controlColor).opacity(0.65))
                            )
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}
