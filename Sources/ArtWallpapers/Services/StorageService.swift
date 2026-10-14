import Foundation

public actor StorageService {
    private let fileManager = FileManager.default
    private let settingsFileName = "settings.json"
    private let historyFileName = "history.json"

    private var appSupportDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ArtWallpapers", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public init() {}

    // MARK: - Directory Management

    public func ensureStorageDirectoryExists(path: String) -> URL {
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath, isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public func fileURL(for item: WallpaperItem, in storagePath: String) -> URL {
        let dir = ensureStorageDirectoryExists(path: storagePath)
        return dir.appendingPathComponent(item.localFileName)
    }

    // MARK: - Saving Images

    public func saveWallpaperImage(
        data: Data,
        artwork: Artwork,
        storagePath: String,
        actualWidth: Int,
        actualHeight: Int
    ) throws -> WallpaperItem {
        let dir = ensureStorageDirectoryExists(path: storagePath)

        // Sanitize title for filename
        let safeTitle = artwork.title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(4)
            .joined(separator: "_")
        let filename = "art_\(artwork.id)_\(safeTitle.isEmpty ? "painting" : safeTitle).jpg"
        let destURL = dir.appendingPathComponent(filename)

        try data.write(to: destURL, options: .atomic)

        let item = WallpaperItem(
            artworkId: artwork.id,
            title: artwork.title,
            artist: artwork.effectiveArtist,
            dateDisplay: artwork.effectiveDate,
            style: artwork.styleTitle,
            badges: artwork.displayBadges,
            localFileName: filename,
            downloadDate: Date(),
            lastAppliedDate: Date(),
            imageWidth: actualWidth,
            imageHeight: actualHeight,
            fileSize: Int64(data.count),
            isPublicDomain: artwork.isPublicDomain ?? true,
            webUrlString: artwork.webUrl?.absoluteString,
            museum: artwork.museum,
            isFavorite: false
        )

        return item
    }

    // MARK: - Pruning / Storage Limit

    public func pruneCache(items: [WallpaperItem], keepLast: Int, storagePath: String) -> [WallpaperItem] {
        guard items.count > keepLast else { return items }

        // Never prune favorites
        let favorites = items.filter { $0.isFavorite }
        let nonFavorites = items.filter { !$0.isFavorite }

        let allowedNonFavorites = max(10, keepLast - favorites.count)
        let sortedNonFavs = nonFavorites.sorted { $0.lastAppliedDate > $1.lastAppliedDate }

        let keptNonFavs = Array(sortedNonFavs.prefix(allowedNonFavorites))
        let toRemove = Array(sortedNonFavs.dropFirst(allowedNonFavorites))

        let dir = ensureStorageDirectoryExists(path: storagePath)
        for old in toRemove {
            let file = dir.appendingPathComponent(old.localFileName)
            try? fileManager.removeItem(at: file)
        }

        return (favorites + keptNonFavs).sorted { $0.lastAppliedDate > $1.lastAppliedDate }
    }

    public func deleteItem(item: WallpaperItem, storagePath: String) {
        let dir = ensureStorageDirectoryExists(path: storagePath)
        let file = dir.appendingPathComponent(item.localFileName)
        try? fileManager.removeItem(at: file)
    }

    // MARK: - Settings Persistence

    public func loadSettings() -> AppSettings {
        let url = appSupportDirectory.appendingPathComponent(settingsFileName)
        guard let data = try? Data(contentsOf: url) else {
            return AppSettings.defaultSettings
        }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            return AppSettings.defaultSettings
        }
    }

    public func saveSettings(_ settings: AppSettings) {
        let url = appSupportDirectory.appendingPathComponent(settingsFileName)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - History Persistence

    public func loadHistory() -> [WallpaperItem] {
        let url = appSupportDirectory.appendingPathComponent(historyFileName)
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        do {
            return try JSONDecoder().decode([WallpaperItem].self, from: data)
        } catch {
            return []
        }
    }

    public func saveHistory(_ items: [WallpaperItem]) {
        let url = appSupportDirectory.appendingPathComponent(historyFileName)
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
