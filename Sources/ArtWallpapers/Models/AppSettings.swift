import Foundation

public enum ImageFitOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case fillScreen = "Fill screen"
    case fitToScreen = "Fit to screen"
    case stretchToFill = "Stretch to fill"
    case center = "Center"

    public var id: String { rawValue }
}

public enum ArtPeriodOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All periods"
    case renaissance = "Renaissance (1400–1600)"
    case baroque = "Baroque & Rococo (1600–1750)"
    case eighteenthCentury = "18th Century"
    case nineteenthCentury = "19th Century"
    case impressionism = "Impressionism & Post-Impressionism"
    case modern = "Modern (1900–1950)"
    case contemporary = "Contemporary (1950–present)"

    public var id: String { rawValue }

    public var queryParam: (dateStart: Int?, dateEnd: Int?) {
        switch self {
        case .all:
            return (nil, nil)
        case .renaissance:
            return (1400, 1600)
        case .baroque:
            return (1600, 1750)
        case .eighteenthCentury:
            return (1700, 1800)
        case .nineteenthCentury:
            return (1800, 1900)
        case .impressionism:
            return (1860, 1910)
        case .modern:
            return (1900, 1950)
        case .contemporary:
            return (1950, nil)
        }
    }
}

public enum SubjectOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All subjects"
    case landscape = "Landscape"
    case portraits = "Portraits"
    case mythology = "Mythology & Religion"
    case battles = "Battles & History"
    case animals = "Animals & Nature"
    case cityscapes = "Cityscapes & Architecture"
    case stillLife = "Still Life"

    public var id: String { rawValue }

    public var searchTerm: String? {
        switch self {
        case .all:
            return nil
        case .landscape:
            return "landscape"
        case .portraits:
            return "portrait"
        case .mythology:
            return "mythology"
        case .battles:
            return "battle"
        case .animals:
            return "animal"
        case .cityscapes:
            return "cityscape architecture"
        case .stillLife:
            return "still life"
        }
    }
}

public enum OrientationOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case landscape = "Landscape"
    case portrait = "Portrait"
    case both = "Both"

    public var id: String { rawValue }
}

public enum ResolutionOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case fourK = "4K (if available)"
    case displayRes = "Display resolution"
    case bestAvailable = "Best available"
    case tenEightyP = "1080p"

    public var id: String { rawValue }

    public func targetWidth(for screenWidth: Int, screenHeight: Int, backingScale: CGFloat) -> Int {
        switch self {
        case .fourK:
            return 3840
        case .displayRes:
            let scaledW = Int(CGFloat(screenWidth) * backingScale)
            return max(scaledW, 2560)
        case .bestAvailable:
            return 4096
        case .tenEightyP:
            return 1920
        }
    }
}

public struct AppSettings: Codable, Sendable {
    public var interval: ChangeInterval
    public var imageFit: ImageFitOption
    public var autoStartAtLogin: Bool
    public var showNotifications: Bool
    public var artPeriod: ArtPeriodOption
    public var subject: SubjectOption
    public var artistQuery: String
    public var onlyPublicDomain: Bool
    public var orientation: OrientationOption
    public var maxResolution: ResolutionOption
    public var keepLastCount: Int
    public var storageLocationPath: String
    public var isPaused: Bool
    public var recentlySeenIds: [Int]

    // Advanced & New Options
    public var enabledMuseums: [MuseumSource]
    public var cycleOnlyFavorites: Bool
    public var enableGlobalHotkey: Bool
    public var multiMonitorIndependent: Bool
    public var plaqueSettings: PlaqueSettings

    public static var defaultStorageLocation: String {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        return pictures.appendingPathComponent("Art Wallpapers").path
    }

    public static let defaultSettings = AppSettings(
        interval: .thirtyMinutes,
        imageFit: .fillScreen,
        autoStartAtLogin: false,
        showNotifications: true,
        artPeriod: .all,
        subject: .all,
        artistQuery: "",
        onlyPublicDomain: true,
        orientation: .landscape,
        maxResolution: .fourK,
        keepLastCount: 1000,
        storageLocationPath: AppSettings.defaultStorageLocation,
        isPaused: false,
        recentlySeenIds: [],
        enabledMuseums: MuseumSource.allCases,
        cycleOnlyFavorites: false,
        enableGlobalHotkey: true,
        multiMonitorIndependent: false,
        plaqueSettings: .defaultSettings
    )
}
