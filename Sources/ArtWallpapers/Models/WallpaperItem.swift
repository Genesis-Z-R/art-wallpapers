import Foundation

public struct WallpaperItem: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let artworkId: Int
    public let title: String
    public let artist: String
    public let dateDisplay: String
    public let style: String?
    public let badges: [String]
    public let localFileName: String
    public let downloadDate: Date
    public let lastAppliedDate: Date
    public let imageWidth: Int
    public let imageHeight: Int
    public let fileSize: Int64
    public let isPublicDomain: Bool
    public let webUrlString: String?
    public let museum: MuseumSource
    public let isFavorite: Bool

    public init(
        id: UUID = UUID(),
        artworkId: Int,
        title: String,
        artist: String,
        dateDisplay: String,
        style: String?,
        badges: [String],
        localFileName: String,
        downloadDate: Date = Date(),
        lastAppliedDate: Date = Date(),
        imageWidth: Int,
        imageHeight: Int,
        fileSize: Int64,
        isPublicDomain: Bool,
        webUrlString: String?,
        museum: MuseumSource = .aic,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.artworkId = artworkId
        self.title = title
        self.artist = artist
        self.dateDisplay = dateDisplay
        self.style = style
        self.badges = badges
        self.localFileName = localFileName
        self.downloadDate = downloadDate
        self.lastAppliedDate = lastAppliedDate
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.fileSize = fileSize
        self.isPublicDomain = isPublicDomain
        self.webUrlString = webUrlString
        self.museum = museum
        self.isFavorite = isFavorite
    }

    public func updatingLastApplied(date: Date = Date()) -> WallpaperItem {
        WallpaperItem(
            id: id,
            artworkId: artworkId,
            title: title,
            artist: artist,
            dateDisplay: dateDisplay,
            style: style,
            badges: badges,
            localFileName: localFileName,
            downloadDate: downloadDate,
            lastAppliedDate: date,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            fileSize: fileSize,
            isPublicDomain: isPublicDomain,
            webUrlString: webUrlString,
            museum: museum,
            isFavorite: isFavorite
        )
    }

    public func togglingFavorite() -> WallpaperItem {
        WallpaperItem(
            id: id,
            artworkId: artworkId,
            title: title,
            artist: artist,
            dateDisplay: dateDisplay,
            style: style,
            badges: badges,
            localFileName: localFileName,
            downloadDate: downloadDate,
            lastAppliedDate: lastAppliedDate,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            fileSize: fileSize,
            isPublicDomain: isPublicDomain,
            webUrlString: webUrlString,
            museum: museum,
            isFavorite: !isFavorite
        )
    }

    public var webUrl: URL? {
        if let webUrlString {
            return URL(string: webUrlString)
        }
        return URL(string: "https://www.artic.edu/artworks/\(artworkId)")
    }
}
