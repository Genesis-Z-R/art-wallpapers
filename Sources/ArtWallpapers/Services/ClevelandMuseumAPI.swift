import Foundation

public actor ClevelandMuseumAPI {
    private let baseURL = URL(string: "https://openaccess-api.clevelandart.org/api/artworks")!
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 25
        configuration.timeoutIntervalForResource = 50
        configuration.httpAdditionalHeaders = [
            "User-Agent": "ArtWallpapers/1.0 (Macintosh; Mac OS X)",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: configuration)
    }

    /// Fetches a candidate painting from Cleveland Museum of Art
    public func fetchRandomPainting(settings: AppSettings, excludingIds: Set<Int>) async throws -> Artwork {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "has_image", value: "1"),
            URLQueryItem(name: "type", value: "Painting"),
            URLQueryItem(name: "limit", value: "30")
        ]

        // Search term based on artist, subject, or default
        let trimmedArtist = settings.artistQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedArtist.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: trimmedArtist))
        } else if let subjectTerm = settings.subject.searchTerm {
            queryItems.append(URLQueryItem(name: "q", value: subjectTerm))
        }

        // Random offset between 0 and 150
        let randomSkip = Int.random(in: 0..<10) * 30
        queryItems.append(URLQueryItem(name: "skip", value: "\(randomSkip)"))

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        components.queryItems = queryItems

        guard let searchURL = components.url else {
            throw ArtAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: searchURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ArtAPIError.networkError("Cleveland search failed")
        }

        struct CMAResponse: Codable {
            struct CMANode: Codable {
                let id: Int
                let title: String?
                let creation_date: String?
                let culture: [String]?
                let technique: String?
                let department: String?
                let url: String?
                struct CMACreator: Codable {
                    let description: String?
                }
                let creators: [CMACreator]?
                struct CMAImages: Codable {
                    struct ImageVariant: Codable {
                        let url: String?
                        let width: String?
                        let height: String?
                    }
                    let web: ImageVariant?
                    let print: ImageVariant?
                }
                let images: CMAImages?
            }
            let data: [CMANode]?
        }

        let decoded = try JSONDecoder().decode(CMAResponse.self, from: data)
        guard let items = decoded.data, !items.isEmpty else {
            throw ArtAPIError.noArtworksFound
        }

        // Filter exclusions and items with valid images
        let eligible = items.filter { item in
            guard let imgUrl = item.images?.print?.url ?? item.images?.web?.url, !imgUrl.isEmpty else {
                return false
            }
            return !excludingIds.contains(item.id)
        }

        let pool = eligible.isEmpty ? items : eligible
        guard let selected = pool.randomElement(),
              let imageURL = selected.images?.print?.url ?? selected.images?.web?.url else {
            throw ArtAPIError.noArtworksFound
        }

        let artist = selected.creators?.first?.description?
            .components(separatedBy: " (").first ?? "Unknown Artist"

        return Artwork(
            id: selected.id,
            title: selected.title ?? "Untitled",
            artistTitle: artist,
            artistDisplay: artist,
            dateDisplay: selected.creation_date,
            imageId: "\(selected.id)",
            isPublicDomain: true,
            thumbnail: ArtworkThumbnail(width: 2560, height: 1600),
            styleTitle: selected.department,
            classificationTitle: selected.technique,
            artworkTypeTitle: "Painting",
            mediumDisplay: selected.technique,
            museum: .cma,
            directImageURLString: imageURL,
            directWebURLString: selected.url
        )
    }
}
