import Foundation

public actor MultiMuseumService {
    private let aicAPI = ArtInstituteAPI()
    private let metAPI = MetMuseumAPI()
    private let cmaAPI = ClevelandMuseumAPI()

    public init() {}

    /// Fetches a random eligible artwork from the enabled museums
    public func fetchRandomArtwork(settings: AppSettings, excludingIds: Set<Int>) async throws -> Artwork {
        let activeMuseums = settings.enabledMuseums.isEmpty ? [MuseumSource.aic] : settings.enabledMuseums
        let shuffledMuseums = activeMuseums.shuffled()

        var lastError: Error = ArtAPIError.noArtworksFound

        for museum in shuffledMuseums {
            do {
                switch museum {
                case .aic:
                    var artwork = try await aicAPI.fetchRandomEligibleArtwork(settings: settings, excludingIds: excludingIds)
                    artwork.museum = .aic
                    return artwork
                case .met:
                    return try await metAPI.fetchRandomPainting(settings: settings, excludingIds: excludingIds)
                case .cma:
                    return try await cmaAPI.fetchRandomPainting(settings: settings, excludingIds: excludingIds)
                }
            } catch {
                lastError = error
                // Try next museum in the shuffled list
            }
        }

        throw lastError
    }
}
