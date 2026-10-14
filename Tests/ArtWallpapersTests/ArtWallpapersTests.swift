import Testing
@testable import ArtWallpapers
import Foundation

@Suite("ArtWallpapers Tests")
struct ArtWallpapersTests {

    @Test("Decodes Artwork JSON from Art Institute API")
    func testArtworkDecoding() throws {
        let json = """
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

        let artwork = try JSONDecoder().decode(Artwork.self, from: json)
        #expect(artwork.id == 28560)
        #expect(artwork.title == "The Bedroom")
        #expect(artwork.effectiveArtist == "Vincent van Gogh")
        #expect(artwork.effectiveDate == "1889")
        #expect(artwork.isLandscape == true)
        #expect(artwork.imageId == "6644829f-f292-c5c4-a73c-0356a6fdbf0d")
        #expect(artwork.isPublicDomain == true)
        #expect(artwork.displayBadges.contains("Post-Impressionism"))
        #expect(artwork.displayBadges.contains("Public Domain"))
    }

    @Test("Calculates ChangeInterval in seconds")
    func testChangeIntervalSeconds() {
        #expect(ChangeInterval.fifteenMinutes.seconds == 900)
        #expect(ChangeInterval.thirtyMinutes.seconds == 1800)
        #expect(ChangeInterval.oneHour.seconds == 3600)
        #expect(ChangeInterval.threeHours.seconds == 10800)
        #expect(ChangeInterval.sixHours.seconds == 21600)
        #expect(ChangeInterval.twelveHours.seconds == 43200)
        #expect(ChangeInterval.daily.seconds == 86400)
    }

    @Test("Calculates target resolution widths")
    func testResolutionCalculations() {
        let displayRes = ResolutionOption.displayRes
        let targetWidth = displayRes.targetWidth(for: 1470, screenHeight: 956, backingScale: 2.0)
        #expect(targetWidth >= 2560)

        let fourK = ResolutionOption.fourK
        #expect(fourK.targetWidth(for: 1470, screenHeight: 956, backingScale: 2.0) == 3840)
    }

    @Test("Maps Art Period query ranges")
    func testArtPeriodQueryMapping() {
        let renaissance = ArtPeriodOption.renaissance.queryParam
        #expect(renaissance.dateStart == 1400)
        #expect(renaissance.dateEnd == 1600)

        let impressionism = ArtPeriodOption.impressionism.queryParam
        #expect(impressionism.dateStart == 1860)
        #expect(impressionism.dateEnd == 1910)
    }

    @Test("Maps Subject search terms")
    func testSubjectSearchTerm() {
        #expect(SubjectOption.landscape.searchTerm == "landscape")
        #expect(SubjectOption.portraits.searchTerm == "portrait")
        #expect(SubjectOption.all.searchTerm == nil)
    }

    @Test("Preserves immutability when updating wallpaper items")
    func testWallpaperItemImmutability() {
        let item = WallpaperItem(
            artworkId: 100,
            title: "Test Painting",
            artist: "Test Artist",
            dateDisplay: "1900",
            style: "Impressionism",
            badges: ["Landscape", "Public Domain"],
            localFileName: "test.jpg",
            imageWidth: 2560,
            imageHeight: 1600,
            fileSize: 1024,
            isPublicDomain: true,
            webUrlString: "https://example.com"
        )

        let newDate = Date().addingTimeInterval(100)
        let updated = item.updatingLastApplied(date: newDate)

        #expect(updated.artworkId == item.artworkId)
        #expect(updated.title == item.title)
        #expect(updated.lastAppliedDate == newDate)
        #expect(item.lastAppliedDate != newDate)
    }
}
