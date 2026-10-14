import Foundation

public enum ChangeInterval: String, CaseIterable, Identifiable, Codable, Sendable {
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case threeHours = "3 hours"
    case sixHours = "6 hours"
    case twelveHours = "12 hours"
    case daily = "Daily"

    public var id: String { rawValue }

    public var seconds: TimeInterval {
        switch self {
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        case .threeHours:
            return 3 * 3600
        case .sixHours:
            return 6 * 3600
        case .twelveHours:
            return 12 * 3600
        case .daily:
            return 24 * 3600
        }
    }
}
