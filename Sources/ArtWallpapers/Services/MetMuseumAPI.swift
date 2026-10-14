import Foundation

public actor MetMuseumAPI {
    private let baseURL = URL(string: "https://collectionapi.metmuseum.org/public/collection")!
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.httpAdditionalHeaders = [
            "User-Agent": "ArtWallpapers/1.0 (Macintosh; Mac OS X)",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: configuration)
    }

    /// Fetches a candidate painting from The Met collection matching settings
    public func fetchRandomPainting(settings: AppSettings, excludingIds: Set<Int>) async throws -> Artwork {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "hasImages", value: "true")
        ]

        if settings.onlyPublicDomain {
            queryItems.append(URLQueryItem(name: "isPublicDomain", value: "true"))
        }

        // Search term based on artist, subject, or default to classic painting
        var queryTerm = "painting"
        let trimmedArtist = settings.artistQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedArtist.isEmpty {
            queryTerm = trimmedArtist
        } else if let subjectTerm = settings.subject.searchTerm {
            queryTerm = subjectTerm
        }

        queryItems.append(URLQueryItem(name: "q", value: queryTerm))

        var searchURLComponents = URLComponents(url: baseURL.appendingPathComponent("v1.1/search"), resolvingAgainstBaseURL: true)!
        searchURLComponents.queryItems = queryItems

        guard let searchURL = searchURLComponents.url else {
            throw ArtAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: searchURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ArtAPIError.networkError("Met search failed")
        }

        struct MetSearchResponse: Codable {
            let total: Int?
            let objectIDs: [Int]?
        }

        let searchResult = try JSONDecoder().decode(MetSearchResponse.self, from: data)
        guard let objectIDs = searchResult.objectIDs, !objectIDs.isEmpty else {
            throw ArtAPIError.noArtworksFound
        }

        // Filter out recently seen IDs
        let candidateIDs = objectIDs.filter { !excludingIds.contains($0) }
        let targetPool = candidateIDs.isEmpty ? objectIDs : candidateIDs

        // Sample up to 8 random IDs to find one with a valid primaryImage
        let sampleIDs = Array(targetPool.shuffled().prefix(10))

        for objID in sampleIDs {
            if let artwork = try? await fetchObjectDetails(objectID: objID) {
                return artwork
            }
        }

        throw ArtAPIError.noArtworksFound
    }

    private func fetchObjectDetails(objectID: Int) async throws -> Artwork {
        let objectURL = baseURL.appendingPathComponent("v1/objects/\(objectID)")
        let (data, response) = try await session.data(from: objectURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ArtAPIError.networkError("Met object lookup failed")
        }

        struct MetObject: Codable {
            let objectID: Int
            let title: String?
            let artistDisplayName: String?
            let objectDate: String?
            let objectBeginDate: Int?
            let objectEndDate: Int?
            let primaryImage: String?
            let primaryImageSmall: String?
            let isPublicDomain: Bool?
            let department: String?
            let classification: String?
            let medium: String?
            let dimensions: String?
            let objectURL: String?
        }

        let obj = try JSONDecoder().decode(MetObject.self, from: data)

        guard let imageURL = obj.primaryImage, !imageURL.isEmpty else {
            throw ArtAPIError.invalidImageData
        }

        return Artwork(
            id: obj.objectID,
            title: obj.title?.isEmpty == false ? obj.title! : "Untitled",
            artistTitle: obj.artistDisplayName,
            artistDisplay: obj.artistDisplayName,
            dateDisplay: obj.objectDate,
            dateStart: obj.objectBeginDate,
            dateEnd: obj.objectEndDate,
            imageId: "\(obj.objectID)",
            isPublicDomain: obj.isPublicDomain ?? true,
            thumbnail: ArtworkThumbnail(width: 1920, height: 1080),
            styleTitle: obj.department,
            classificationTitle: obj.classification,
            artworkTypeTitle: "Painting",
            mediumDisplay: obj.medium,
            dimensions: obj.dimensions,
            museum: .met,
            directImageURLString: imageURL,
            directWebURLString: obj.objectURL
        )
    }
}
