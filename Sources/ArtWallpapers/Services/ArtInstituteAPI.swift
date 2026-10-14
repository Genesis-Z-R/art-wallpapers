import Foundation

public enum ArtAPIError: LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case serverError(Int)
    case decodingError(String)
    case noArtworksFound
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The Art Institute API URL is invalid."
        case .networkError(let message):
            return "Network connection error: \(message)"
        case .serverError(let code):
            return "Art Institute server returned error code \(code)."
        case .decodingError(let message):
            return "Failed to decode artwork data: \(message)"
        case .noArtworksFound:
            return "No eligible artworks found matching your current filter settings."
        case .invalidImageData:
            return "Downloaded image was corrupt or not a valid image format."
        }
    }
}

public actor ArtInstituteAPI {
    private let baseURL = URL(string: "https://api.artic.edu/api/v1")!
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 60
        configuration.httpAdditionalHeaders = [
            "User-Agent": "ArtWallpapers/1.0 (Macintosh; Mac OS X)",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: configuration)
    }

    /// Fetches a candidate artwork based on current user settings and exclusion list
    public func fetchRandomEligibleArtwork(settings: AppSettings, excludingIds: Set<Int>) async throws -> Artwork {
        // Query candidate artworks with a random offset
        let artworks = try await searchArtworks(settings: settings, limit: 25)

        // Filter artworks by exclusions, orientation, and image_id
        let eligible = artworks.filter { artwork in
            guard let imageId = artwork.imageId, !imageId.isEmpty else { return false }
            if excludingIds.contains(artwork.id) { return false }

            switch settings.orientation {
            case .landscape:
                if let w = artwork.thumbnail?.width, let h = artwork.thumbnail?.height {
                    return w >= h
                }
                return true
            case .portrait:
                if let w = artwork.thumbnail?.width, let h = artwork.thumbnail?.height {
                    return h > w
                }
                return true
            case .both:
                return true
            }
        }

        if let selected = eligible.randomElement() {
            return selected
        }

        // If all candidate artworks were excluded or filtered out, try without recent exclusions
        if let fallback = artworks.first(where: { $0.imageId != nil && !$0.imageId!.isEmpty }) {
            return fallback
        }

        throw ArtAPIError.noArtworksFound
    }

    /// Searches artworks using POST elasticsearch query with filters
    public func searchArtworks(settings: AppSettings, limit: Int = 20) async throws -> [Artwork] {
        let searchURL = baseURL.appendingPathComponent("artworks/search")

        var mustClauses: [[String: Any]] = [
            ["exists": ["field": "image_id"]]
        ]

        if settings.onlyPublicDomain {
            mustClauses.append(["term": ["is_public_domain": true]])
        }

        // Restrict to paintings by default for classical wallpaper quality
        mustClauses.append([
            "bool": [
                "should": [
                    ["term": ["artwork_type_title.keyword": "Painting"]],
                    ["term": ["classification_title.keyword": "painting"]]
                ],
                "minimum_should_match": 1
            ]
        ])

        // Filter by art period date range
        let dateFilter = settings.artPeriod.queryParam
        if dateFilter.dateStart != nil || dateFilter.dateEnd != nil {
            var rangeDict: [String: Any] = [:]
            if let start = dateFilter.dateStart {
                rangeDict["gte"] = start
            }
            if let end = dateFilter.dateEnd {
                rangeDict["lte"] = end
            }
            mustClauses.append(["range": ["date_start": rangeDict]])
        }

        // Subject filter
        if let subjectTerm = settings.subject.searchTerm {
            mustClauses.append([
                "multi_match": [
                    "query": subjectTerm,
                    "fields": ["subject_titles^3", "title^2", "style_title", "description"]
                ]
            ])
        }

        // Artist filter
        let trimmedArtist = settings.artistQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedArtist.isEmpty {
            mustClauses.append([
                "multi_match": [
                    "query": trimmedArtist,
                    "fields": ["artist_title^4", "artist_display^2"]
                ]
            ])
        }

        // Random offset for variety (between 0 and 200)
        let randomOffset = Int.random(in: 0..<30) * limit

        let requestBody: [String: Any] = [
            "resources": "artworks",
            "fields": [
                "id", "title", "artist_title", "artist_display", "date_display",
                "date_start", "date_end", "image_id", "is_public_domain",
                "thumbnail", "style_title", "style_titles", "subject_titles",
                "classification_title", "artwork_type_title", "medium_display",
                "credit_line", "dimensions"
            ],
            "query": [
                "bool": [
                    "must": mustClauses
                ]
            ],
            "limit": limit,
            "from": randomOffset
        ]

        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArtAPIError.networkError("Invalid response from server")
        }

        guard httpResponse.statusCode == 200 else {
            throw ArtAPIError.serverError(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(ArtworkSearchResponse.self, from: data)
            return decoded.data
        } catch {
            throw ArtAPIError.decodingError(error.localizedDescription)
        }
    }
}
