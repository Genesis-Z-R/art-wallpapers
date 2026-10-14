import SwiftUI
import AppKit

@MainActor
final class CollectionBrowserViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var showOnlyFavorites: Bool = false
    @Published var selectedItem: WallpaperItem?
    @Published var loadedThumbnails: [UUID: NSImage] = [:]
    @Published var loadedFullImages: [UUID: NSImage] = [:]

    func loadThumbnail(for item: WallpaperItem, storagePath: String) {
        if loadedThumbnails[item.id] != nil { return }
        let dir = (storagePath as NSString).expandingTildeInPath
        let fileURL = URL(fileURLWithPath: dir).appendingPathComponent(item.localFileName)
        if let image = ImageCache.shared.image(for: fileURL) {
            loadedThumbnails[item.id] = image
        }
    }

    func loadFullImage(for item: WallpaperItem, storagePath: String) {
        if loadedFullImages[item.id] != nil { return }
        let dir = (storagePath as NSString).expandingTildeInPath
        let fileURL = URL(fileURLWithPath: dir).appendingPathComponent(item.localFileName)
        if let image = ImageCache.shared.image(for: fileURL) {
            loadedFullImages[item.id] = image
        }
    }
}

@MainActor
public struct CollectionBrowserView: View {
    @ObservedObject var manager: WallpaperManager
    @StateObject private var viewModel = CollectionBrowserViewModel()

    @MainActor
    public init(manager: WallpaperManager) {
        self.manager = manager
    }

    public var filteredItems: [WallpaperItem] {
        var items = manager.history
        if viewModel.showOnlyFavorites {
            items = items.filter { $0.isFavorite }
        }

        let query = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(query) ||
                item.artist.localizedCaseInsensitiveContains(query) ||
                item.dateDisplay.localizedCaseInsensitiveContains(query) ||
                item.museum.shortName.localizedCaseInsensitiveContains(query) ||
                (item.style?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        return items
    }

    private var favoritesCount: Int {
        manager.history.filter { $0.isFavorite }.count
    }

    public var body: some View {
        HSplitView {
            // Left list / grid of paintings
            VStack(spacing: 0) {
                // Search bar & Filter Tabs
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search title, artist, or style...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    // Tab selector
                    HStack(spacing: 8) {
                        Button(action: { viewModel.showOnlyFavorites = false }) {
                            Text("All (\(manager.history.count))")
                                .font(.system(size: 11, weight: !viewModel.showOnlyFavorites ? .bold : .regular))
                                .foregroundColor(!viewModel.showOnlyFavorites ? .primary : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(!viewModel.showOnlyFavorites ? Color.accentColor.opacity(0.18) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: { viewModel.showOnlyFavorites = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                                Text("Favorites (\(favoritesCount))")
                                    .font(.system(size: 11, weight: viewModel.showOnlyFavorites ? .bold : .regular))
                                    .foregroundColor(viewModel.showOnlyFavorites ? .primary : .secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(viewModel.showOnlyFavorites ? Color.red.opacity(0.18) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
                .padding(12)

                if filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: viewModel.showOnlyFavorites ? "heart.slash" : "photo.stack")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text(viewModel.showOnlyFavorites ? "No favorited paintings yet" : (manager.history.isEmpty ? "No downloaded wallpapers yet" : "No paintings match your search"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 14)], spacing: 14) {
                            ForEach(filteredItems) { item in
                                CollectionThumbnailCard(
                                    item: item,
                                    thumbnail: viewModel.loadedThumbnails[item.id],
                                    isSelected: viewModel.selectedItem?.id == item.id,
                                    isCurrent: manager.currentWallpaper?.id == item.id
                                ) {
                                    viewModel.selectedItem = item
                                }
                                .onAppear {
                                    viewModel.loadThumbnail(for: item, storagePath: manager.settings.storageLocationPath)
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .frame(minWidth: 320, maxWidth: .infinity)

            // Right detail sidebar
            if let item = (viewModel.selectedItem.flatMap { sel in manager.history.first(where: { $0.id == sel.id }) }) ?? manager.currentWallpaper ?? manager.history.first {
                CollectionDetailView(
                    item: item,
                    fullImage: viewModel.loadedFullImages[item.id],
                    storagePath: manager.settings.storageLocationPath,
                    isCurrent: manager.currentWallpaper?.id == item.id,
                    onToggleFavorite: {
                        manager.toggleFavorite(item: item)
                    },
                    onApply: {
                        manager.applyExistingWallpaper(item)
                    },
                    onDelete: {
                        manager.deleteHistoryItem(item)
                        if viewModel.selectedItem?.id == item.id {
                            viewModel.selectedItem = manager.history.first
                        }
                    }
                )
                .frame(width: 280)
                .onAppear {
                    viewModel.loadFullImage(for: item, storagePath: manager.settings.storageLocationPath)
                }
                .onChange(of: item.id) { _ in
                    viewModel.loadFullImage(for: item, storagePath: manager.settings.storageLocationPath)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 480)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }
}

// MARK: - Thumbnail Card

private struct CollectionThumbnailCard: View {
    let item: WallpaperItem
    let thumbnail: NSImage?
    let isSelected: Bool
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .aspectRatio(16/10, contentMode: .fit)

                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 110)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 110)
                    }

                    HStack {
                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                                .padding(5)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }

                        Spacer()

                        if isCurrent {
                            Text("ACTIVE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.85))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(6)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(item.artist)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 2)

                    Text(item.museum.shortName)
                        .font(.system(size: 9))
                        .foregroundColor(.accentColor.opacity(0.9))
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail View

private struct CollectionDetailView: View {
    let item: WallpaperItem
    let fullImage: NSImage?
    let storagePath: String
    let isCurrent: Bool
    let onToggleFavorite: () -> Void
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .aspectRatio(16/10, contentMode: .fit)

                    if let fullImage {
                        Image(nsImage: fullImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxHeight: 180)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Text(item.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(item.dateDisplay)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                // Badges
                FlowLayout(spacing: 4) {
                    Text(item.museum.shortName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.15)))

                    ForEach(item.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                }

                // Details Table
                VStack(spacing: 6) {
                    DetailRow(label: "Museum", value: item.museum.rawValue)
                    DetailRow(label: "Resolution", value: "\(item.imageWidth) × \(item.imageHeight)")
                    DetailRow(label: "File Size", value: ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                    DetailRow(label: "Downloaded", value: item.downloadDate.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.system(size: 10))
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor).opacity(0.5)))

                // Actions
                VStack(spacing: 8) {
                    // Favorite Toggle
                    Button(action: onToggleFavorite) {
                        HStack {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(item.isFavorite ? .red : .primary)
                            Text(item.isFavorite ? "In Favorites" : "Add to Favorites")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onApply) {
                        HStack {
                            Image(systemName: isCurrent ? "checkmark.circle.fill" : "display")
                            Text(isCurrent ? "Current Wallpaper" : "Set as Wallpaper")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCurrent)

                    HStack(spacing: 8) {
                        Button(action: showInFinder) {
                            HStack {
                                Image(systemName: "folder")
                                Text("In Finder")
                            }
                            .frame(maxWidth: .infinity)
                        }

                        if let url = item.webUrl {
                            Button(action: { NSWorkspace.shared.open(url) }) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text(item.museum.shortName)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .font(.system(size: 11))

                    Button(role: .destructive, action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete from Collection")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
    }

    private func showInFinder() {
        let dir = (storagePath as NSString).expandingTildeInPath
        let fileURL = URL(fileURLWithPath: dir).appendingPathComponent(item.localFileName)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// Flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
