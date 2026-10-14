import Foundation

public struct ArtworkSearchResponse: Codable, Sendable {
    public let pagination: PaginationInfo
    public let data: [Artwork]
    public let config: AICConfig?
}

public struct AICConfig: Codable, Sendable {
    public let iiifUrl: String?
    public let websiteUrl: String?

    enum CodingKeys: String, CodingKey {
        case iiifUrl = "iiif_url"
        case websiteUrl = "website_url"
    }
}

public struct PaginationInfo: Codable, Sendable {
    public let total: Int
    public let limit: Int
    public let offset: Int
    public let totalPages: Int
    public let currentPage: Int

    enum CodingKeys: String, CodingKey {
        case total, limit, offset
        case totalPages = "total_pages"
        case currentPage = "current_page"
    }
}

public struct ArtworkThumbnail: Codable, Sendable {
    public let lqip: String?
    public let width: Int?
    public let height: Int?
    public let altText: String?

    enum CodingKeys: String, CodingKey {
        case lqip, width, height
        case altText = "alt_text"
    }

    public init(lqip: String? = nil, width: Int? = nil, height: Int? = nil, altText: String? = nil) {
        self.lqip = lqip
        self.width = width
        self.height = height
        self.altText = altText
    }
}

public struct Artwork: Codable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let artistTitle: String?
    public let artistDisplay: String?
    public let dateDisplay: String?
    public let dateStart: Int?
    public let dateEnd: Int?
    public let imageId: String?
    public let isPublicDomain: Bool?
    public let thumbnail: ArtworkThumbnail?
    public let styleTitle: String?
    public let styleTitles: [String]?
    public let subjectTitles: [String]?
    public let classificationTitle: String?
    public let artworkTypeTitle: String?
    public let mediumDisplay: String?
    public let creditLine: String?
    public let dimensions: String?

    // Multi-museum extensions
    public var museum: MuseumSource = .aic
    public var directImageURLString: String? = nil
    public var directWebURLString: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, title, dimensions
        case artistTitle = "artist_title"
        case artistDisplay = "artist_display"
        case dateDisplay = "date_display"
        case dateStart = "date_start"
        case dateEnd = "date_end"
        case imageId = "image_id"
        case isPublicDomain = "is_public_domain"
        case thumbnail
        case styleTitle = "style_title"
        case styleTitles = "style_titles"
        case subjectTitles = "subject_titles"
        case classificationTitle = "classification_title"
        case artworkTypeTitle = "artwork_type_title"
        case mediumDisplay = "medium_display"
        case creditLine = "credit_line"
        case museum
        case directImageURLString
        case directWebURLString
    }

    public init(
        id: Int,
        title: String,
        artistTitle: String?,
        artistDisplay: String? = nil,
        dateDisplay: String?,
        dateStart: Int? = nil,
        dateEnd: Int? = nil,
        imageId: String?,
        isPublicDomain: Bool? = true,
        thumbnail: ArtworkThumbnail? = nil,
        styleTitle: String? = nil,
        styleTitles: [String]? = nil,
        subjectTitles: [String]? = nil,
        classificationTitle: String? = nil,
        artworkTypeTitle: String? = nil,
        mediumDisplay: String? = nil,
        creditLine: String? = nil,
        dimensions: String? = nil,
        museum: MuseumSource = .aic,
        directImageURLString: String? = nil,
        directWebURLString: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artistTitle = artistTitle
        self.artistDisplay = artistDisplay
        self.dateDisplay = dateDisplay
        self.dateStart = dateStart
        self.dateEnd = dateEnd
        self.imageId = imageId
        self.isPublicDomain = isPublicDomain
        self.thumbnail = thumbnail
        self.styleTitle = styleTitle
        self.styleTitles = styleTitles
        self.subjectTitles = subjectTitles
        self.classificationTitle = classificationTitle
        self.artworkTypeTitle = artworkTypeTitle
        self.mediumDisplay = mediumDisplay
        self.creditLine = creditLine
        self.dimensions = dimensions
        self.museum = museum
        self.directImageURLString = directImageURLString
        self.directWebURLString = directWebURLString
    }

    public var effectiveArtist: String {
        if let artist = artistTitle, !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return artist
        }
        if let display = artistDisplay, !display.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return display.components(separatedBy: " (").first ?? display
        }
        return "Unknown Artist"
    }

    public var effectiveDate: String {
        if let date = dateDisplay, !date.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return date
        }
        if let start = dateStart {
            return "\(start)"
        }
        return "Date Unknown"
    }

    public var isLandscape: Bool {
        guard let w = thumbnail?.width, let h = thumbnail?.height, w > 0, h > 0 else {
            return true
        }
        return w >= h
    }

    public var displayBadges: [String] {
        var badges: [String] = [museum.shortName]
        if let style = styleTitle, !style.isEmpty {
            badges.append(style)
        }
        if let subject = subjectTitles?.first, !subject.isEmpty, subject != styleTitle {
            badges.append(subject.capitalized)
        }
        if isPublicDomain == true {
            badges.append("Public Domain")
        }
        return Array(badges.prefix(3))
    }

    public var webUrl: URL? {
        if let direct = directWebURLString, let url = URL(string: direct) {
            return url
        }
        switch museum {
        case .aic:
            return URL(string: "https://www.artic.edu/artworks/\(id)")
        case .met:
            return URL(string: "https://www.metmuseum.org/art/collection/search/\(id)")
        case .cma:
            return URL(string: "https://www.clevelandart.org/art/\(id)")
        }
    }
}
