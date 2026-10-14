import Foundation
import AppKit

public final class ImageCache: @unchecked Sendable {
    public static let shared = ImageCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 60
    }

    public func image(for fileURL: URL) -> NSImage? {
        let key = fileURL.path as NSString
        if let existing = cache.object(forKey: key) {
            return existing
        }
        guard let data = try? Data(contentsOf: fileURL),
              let img = NSImage(data: data) else {
            return nil
        }
        cache.setObject(img, forKey: key)
        return img
    }

    public func setImage(_ image: NSImage, for fileURL: URL) {
        let key = fileURL.path as NSString
        cache.setObject(image, forKey: key)
    }

    public func removeImage(for fileURL: URL) {
        let key = fileURL.path as NSString
        cache.removeObject(forKey: key)
    }
}
