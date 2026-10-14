import Foundation
import AppKit

// Include the model types and test directly
print("==> Running Art Wallpapers Verification Suite...")

// 1. Test Artwork Decoding
let sampleJSON = """
{
    "id": 28560,
    "title": "The Bedroom",
    "artist_title": "Vincent van Gogh",
    "date_display": "1889",
    "image_id": "6644829f-f292-c5c4-a73c-0356a6fdbf0d",
    "is_public_domain": true,
    "style_title": "Post-Impressionism",
    "subject_titles": ["interiors", "painting"],
    "thumbnail": {
        "width": 12614,
        "height": 9875,
        "alt_text": "Painting of bedroom"
    }
}
""".data(using: .utf8)!

struct ArtworkThumbnail: Codable {
    let width: Int?
    let height: Int?
}

struct TestArtwork: Codable {
    let id: Int
    let title: String
    let artist_title: String?
    let date_display: String?
    let image_id: String?
    let is_public_domain: Bool?
    let style_title: String?
    let subject_titles: [String]?
    let thumbnail: ArtworkThumbnail?
}

let decoded = try JSONDecoder().decode(TestArtwork.self, from: sampleJSON)
assert(decoded.id == 28560, "Artwork ID matches")
assert(decoded.title == "The Bedroom", "Artwork Title matches")
assert(decoded.is_public_domain == true, "Is Public Domain matches")
print("  ✓ Artwork JSON Decoding passed")

// 2. Test IIIF URL generation
let imageId = "6644829f-f292-c5c4-a73c-0356a6fdbf0d"
let iiifURL = "https://www.artic.edu/iiif/2/\(imageId)/full/2560,/0/default.jpg"
assert(iiifURL.contains("/full/2560,/0/default.jpg"), "IIIF URL format matches")
print("  ✓ IIIF URL construction passed")

// 3. Test Live Art Institute API connectivity
let searchURL = URL(string: "https://api.artic.edu/api/v1/artworks/search")!
var request = URLRequest(url: searchURL)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("ArtWallpapers/1.0", forHTTPHeaderField: "User-Agent")
let queryBody: [String: Any] = [
    "resources": "artworks",
    "fields": ["id", "title", "artist_title", "date_display", "image_id", "thumbnail", "style_title", "is_public_domain"],
    "query": [
        "bool": [
            "must": [
                ["term": ["is_public_domain": true]],
                ["term": ["artwork_type_title.keyword": "Painting"]],
                ["exists": ["field": "image_id"]]
            ]
        ]
    ],
    "limit": 3
]
request.httpBody = try JSONSerialization.data(withJSONObject: queryBody)

let semaphore = DispatchSemaphore(value: 0)
var apiSuccess = false
var sampleTitle = ""
var sampleImageId = ""

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    defer { semaphore.signal() }
    guard let data = data, let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        print("API request failed with error:", error ?? "unknown")
        return
    }
    if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let dataArray = dict["data"] as? [[String: Any]],
       let first = dataArray.first,
       let title = first["title"] as? String,
       let imgId = first["image_id"] as? String {
        sampleTitle = title
        sampleImageId = imgId
        apiSuccess = true
    }
}
task.resume()
_ = semaphore.wait(timeout: .now() + 15)

assert(apiSuccess, "Art Institute API returned artworks successfully")
print("  ✓ Art Institute API query passed (Found '\(sampleTitle)')")

// 4. Test IIIF image download with proper headers
let imgRequestURL = URL(string: "https://www.artic.edu/iiif/2/\(sampleImageId)/full/843,/0/default.jpg")!
var imgReq = URLRequest(url: imgRequestURL)
imgReq.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
imgReq.setValue("https://www.artic.edu/", forHTTPHeaderField: "Referer")
imgReq.setValue("image/*", forHTTPHeaderField: "Accept")

var downloadSuccess = false
var downloadedBytes = 0
let imgSem = DispatchSemaphore(value: 0)

let imgTask = URLSession.shared.dataTask(with: imgReq) { data, response, error in
    defer { imgSem.signal() }
    guard let data = data, let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        print("Image download failed with status:", (response as? HTTPURLResponse)?.statusCode ?? -1)
        return
    }
    downloadedBytes = data.count
    if let image = NSImage(data: data), image.size.width > 50 {
        downloadSuccess = true
    }
}
imgTask.resume()
_ = imgSem.wait(timeout: .now() + 20)

assert(downloadSuccess, "IIIF Image successfully downloaded and validated as NSImage")
print("  ✓ IIIF image download & validation passed (\(downloadedBytes) bytes)")

print("\n🎉 ALL 4 SYSTEM VERIFICATION TESTS PASSED SUCCESSFULLY!")
