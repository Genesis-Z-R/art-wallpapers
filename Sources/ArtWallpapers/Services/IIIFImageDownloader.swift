import Foundation
import AppKit

public actor IIIFImageDownloader {
    private let iiifBase = "https://www.artic.edu/iiif/2"
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 45
        config.timeoutIntervalForResource = 120
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Referer": "https://www.artic.edu/",
            "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
            "Sec-Fetch-Dest": "image",
            "Sec-Fetch-Mode": "no-cors",
            "Sec-Fetch-Site": "same-origin"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Unified download function for any Artwork (IIIF or direct URL)
    public func downloadImage(
        for artwork: Artwork,
        targetWidth: Int
    ) async throws -> (data: Data, actualWidth: Int, actualHeight: Int) {
        if let directURL = artwork.directImageURLString, !directURL.isEmpty {
            return try await downloadDirectImage(urlString: directURL)
        }
        guard let imageId = artwork.imageId, !imageId.isEmpty else {
            throw ArtAPIError.invalidImageData
        }
        return try await downloadArtworkImage(imageId: imageId, targetWidth: targetWidth)
    }

    /// Downloads from direct URL (The Met, Cleveland Museum, etc.)
    public func downloadDirectImage(
        urlString: String
    ) async throws -> (data: Data, actualWidth: Int, actualHeight: Int) {
        guard let url = URL(string: urlString) else {
            throw ArtAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ArtAPIError.networkError("Direct image download returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        if let nsImage = NSImage(data: data) {
            let pixelSize = nsImage.representations.first.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) }
                ?? nsImage.size
            let actualW = Int(pixelSize.width)
            let actualH = Int(pixelSize.height)

            if actualW > 100 && actualH > 100 {
                return (data, actualW, actualH)
            }
        }

        throw ArtAPIError.invalidImageData
    }

    /// Constructs the IIIF URL for a given image_id and target width
    public func imageURL(imageId: String, width: Int) -> URL? {
        let urlString = "\(iiifBase)/\(imageId)/full/\(width),/0/default.jpg"
        return URL(string: urlString)
    }

    /// Downloads the image data with fallback resolutions if needed
    public func downloadArtworkImage(
        imageId: String,
        targetWidth: Int
    ) async throws -> (data: Data, actualWidth: Int, actualHeight: Int) {
        let candidateWidths = [targetWidth, 2560, 1686, 843].filter { $0 <= max(targetWidth, 2560) }
        var uniqueWidths: [Int] = []
        for w in candidateWidths {
            if !uniqueWidths.contains(w) {
                uniqueWidths.append(w)
            }
        }

        var lastError: Error = ArtAPIError.invalidImageData

        for w in uniqueWidths {
            guard let url = imageURL(imageId: imageId, width: w) else { continue }
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    continue
                }

                if let nsImage = NSImage(data: data) {
                    let pixelSize = nsImage.representations.first.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) }
                        ?? nsImage.size
                    let actualW = Int(pixelSize.width)
                    let actualH = Int(pixelSize.height)

                    if actualW > 100 && actualH > 100 {
                        return (data, actualW, actualH)
                    }
                }
            } catch {
                lastError = error
            }
        }

        throw lastError
    }
}
