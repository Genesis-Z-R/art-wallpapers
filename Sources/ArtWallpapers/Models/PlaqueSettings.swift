import Foundation

public enum PlaquePosition: String, CaseIterable, Identifiable, Codable, Sendable {
    case bottomRight = "Bottom Right"
    case bottomLeft = "Bottom Left"
    case topRight = "Top Right"
    case topLeft = "Top Left"

    public var id: String { rawValue }
}

public enum PlaqueDuration: String, CaseIterable, Identifiable, Codable, Sendable {
    case fiveSeconds = "5 seconds"
    case tenSeconds = "10 seconds"
    case fifteenSeconds = "15 seconds"
    case thirtySeconds = "30 seconds"
    case permanent = "Permanent"

    public var id: String { rawValue }

    public var seconds: TimeInterval {
        switch self {
        case .fiveSeconds: return 5
        case .tenSeconds: return 10
        case .fifteenSeconds: return 15
        case .thirtySeconds: return 30
        case .permanent: return 0 // 0 indicates permanent
        }
    }

    public var isPermanent: Bool {
        self == .permanent
    }
}

public struct PlaqueSettings: Codable, Sendable, Equatable {
    public var isEnabled: Bool
    public var stayOnMainDesktopOnly: Bool
    public var position: PlaquePosition
    public var duration: PlaqueDuration
    public var showTitle: Bool
    public var showArtist: Bool
    public var showYear: Bool
    public var showMuseum: Bool

    public init(
        isEnabled: Bool = true,
        stayOnMainDesktopOnly: Bool = true,
        position: PlaquePosition = .bottomRight,
        duration: PlaqueDuration = .tenSeconds,
        showTitle: Bool = true,
        showArtist: Bool = true,
        showYear: Bool = true,
        showMuseum: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.stayOnMainDesktopOnly = stayOnMainDesktopOnly
        self.position = position
        self.duration = duration
        self.showTitle = showTitle
        self.showArtist = showArtist
        self.showYear = showYear
        self.showMuseum = showMuseum
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        self.stayOnMainDesktopOnly = try container.decodeIfPresent(Bool.self, forKey: .stayOnMainDesktopOnly) ?? true
        self.position = try container.decodeIfPresent(PlaquePosition.self, forKey: .position) ?? .bottomRight
        self.duration = try container.decodeIfPresent(PlaqueDuration.self, forKey: .duration) ?? .tenSeconds
        self.showTitle = try container.decodeIfPresent(Bool.self, forKey: .showTitle) ?? true
        self.showArtist = try container.decodeIfPresent(Bool.self, forKey: .showArtist) ?? true
        self.showYear = try container.decodeIfPresent(Bool.self, forKey: .showYear) ?? true
        self.showMuseum = try container.decodeIfPresent(Bool.self, forKey: .showMuseum) ?? true
    }

    public static let defaultSettings = PlaqueSettings(
        isEnabled: true,
        stayOnMainDesktopOnly: true,
        position: .bottomRight,
        duration: .tenSeconds,
        showTitle: true,
        showArtist: true,
        showYear: true,
        showMuseum: true
    )
}
